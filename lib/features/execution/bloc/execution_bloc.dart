import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/plan_step.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/storage/session_repository.dart';
import 'ticker.dart';
import '../../../core/logging/app_log.dart';

part 'execution_event.dart';
part 'execution_state.dart';

/// Walks the user through a plan one step at a time.
///
/// The rules that matter, all of them deliberate:
///
/// * A timer step never starts by itself. It waits for Play — including the
///   step the workout advances to on its own when a countdown hits zero.
/// * Reps and open steps have no clock; only Next moves them on.
/// * −10s is a timer-step control. Taking the countdown to zero ends the step
///   the same way as letting it run out: the step counts as done, not skipped.
/// * The session is written the moment the page opens, because that is what
///   makes the day count towards the streak, and rewritten when it ends.
class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  ExecutionBloc({
    required Plan plan,
    required SessionRepository sessionRepository,
    Ticker ticker = const Ticker(),
    DateTime Function() now = DateTime.now,
  }) : _sessionRepository = sessionRepository,
       _ticker = ticker,
       _now = now,
       super(
         ExecutionState(
           plan: plan,
           sessionId: 'session-${now().microsecondsSinceEpoch}',
           startedAt: now(),
           remainingSeconds: plan.steps.first.durationSeconds ?? 0,
         ),
       ) {
    on<ExecutionStarted>(_onStarted);
    on<ExecutionPrimaryPressed>(_onPrimaryPressed);
    on<ExecutionSkipped>(_onSkipped);
    on<ExecutionSkipUndone>(_onSkipUndone);
    on<ExecutionTimerAdjusted>(_onTimerAdjusted);
    on<ExecutionTicked>(_onTicked);
    on<ExecutionAbandoned>(_onAbandoned);
  }

  final SessionRepository _sessionRepository;
  final Ticker _ticker;
  final DateTime Function() _now;

  StreamSubscription<void>? _tickerSubscription;

  Future<void> _onStarted(
    ExecutionStarted event,
    Emitter<ExecutionState> emit,
  ) async {
    // Written before anything else happens: opening the page is what counts.
    await _saveSession(state);

    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker.ticks().listen((_) {
      add(const ExecutionTicked());
    });
  }

  Future<void> _onPrimaryPressed(
    ExecutionPrimaryPressed event,
    Emitter<ExecutionState> emit,
  ) async {
    if (state.isFinished) return;

    switch (state.primaryAction) {
      case PrimaryAction.play:
        emit(state.copyWith(isTimerRunning: true, canUndoSkip: false));
      case PrimaryAction.pause:
        emit(state.copyWith(isTimerRunning: false));
      case PrimaryAction.next:
        await _advance(emit, skipped: false);
    }
  }

  Future<void> _onSkipped(
    ExecutionSkipped event,
    Emitter<ExecutionState> emit,
  ) async {
    if (state.isFinished) return;
    await _advance(emit, skipped: true);
  }

  void _onSkipUndone(ExecutionSkipUndone event, Emitter<ExecutionState> emit) {
    if (state.isFinished || !state.canUndoSkip) return;

    final previous = state.currentIndex - 1;
    emit(
      state.copyWith(
        currentIndex: previous,
        remainingSeconds: state.plan.steps[previous].durationSeconds ?? 0,
        isTimerRunning: false,
        stepsSkipped: state.stepsSkipped - 1,
        canUndoSkip: false,
      ),
    );
  }

  Future<void> _onTimerAdjusted(
    ExecutionTimerAdjusted event,
    Emitter<ExecutionState> emit,
  ) async {
    if (!state.canAdjustTimer) return;

    final remaining = math.max(
      0,
      state.remainingSeconds - AppConfig.timerAdjustmentSeconds,
    );

    if (remaining == 0) {
      // Reaching zero ends the step, however it got there.
      await _advance(emit, skipped: false);
      return;
    }

    emit(state.copyWith(remainingSeconds: remaining));
  }

  Future<void> _onTicked(
    ExecutionTicked event,
    Emitter<ExecutionState> emit,
  ) async {
    if (state.isFinished) return;

    final step = state.currentStep;
    if (step == null) return;

    final isCountingDown = step.isTimer && state.isTimerRunning;

    // A stopped or paused countdown is not work; anything else is.
    if (step.isTimer && !state.isTimerRunning) return;

    final elapsed = state.totalActiveSeconds + 1;

    if (!isCountingDown) {
      emit(state.copyWith(totalActiveSeconds: elapsed));
      return;
    }

    final remaining = state.remainingSeconds - 1;
    if (remaining > 0) {
      emit(
        state.copyWith(
          remainingSeconds: remaining,
          totalActiveSeconds: elapsed,
        ),
      );
      return;
    }

    AppLog.info('workout', 'step ${state.stepNumber} timer ran out');
    await _advance(
      emit,
      skipped: false,
      state: state.copyWith(totalActiveSeconds: elapsed),
    );
  }

  Future<void> _onAbandoned(
    ExecutionAbandoned event,
    Emitter<ExecutionState> emit,
  ) async {
    if (state.isFinished) return;

    final abandoned = state.copyWith(status: ExecutionStatus.abandoned);
    await _finish(abandoned);
    emit(abandoned);
  }

  /// Moves to the next step, or ends the workout if there is no next step.
  ///
  /// [state] lets a caller hand in an already-updated state, so a tick can
  /// record its second and advance in one emit.
  Future<void> _advance(
    Emitter<ExecutionState> emit, {
    required bool skipped,
    ExecutionState? state,
  }) async {
    final current = state ?? this.state;

    final tallied = current.copyWith(
      stepsCompleted: current.stepsCompleted + (skipped ? 0 : 1),
      stepsSkipped: current.stepsSkipped + (skipped ? 1 : 0),
      canUndoSkip: skipped,
    );

    final nextIndex = current.currentIndex + 1;

    if (nextIndex >= current.plan.steps.length) {
      final finished = tallied.copyWith(
        currentIndex: nextIndex,
        isTimerRunning: false,
        remainingSeconds: 0,
        status: ExecutionStatus.completed,
      );
      // Saved before the state changes, not after: the summary is the screen
      // that offers a way back to the Dashboard, and the Dashboard reads this
      // session for the streak and the calendar. Emitting first would let the
      // user leave through a window where the workout had visibly finished but
      // was not yet on disk.
      await _finish(finished);
      emit(finished);
      return;
    }

    emit(
      tallied.copyWith(
        currentIndex: nextIndex,
        remainingSeconds: tallied.plan.steps[nextIndex].durationSeconds ?? 0,
        // The next timer waits for Play too.
        isTimerRunning: false,
      ),
    );
  }

  Future<void> _finish(ExecutionState state) async {
    _tickerSubscription?.cancel();
    _tickerSubscription = null;
    await _saveSession(state, endedAt: _now());
    AppLog.info(
      'workout',
      '${state.status.name} "${state.plan.name}": '
          '${state.stepsCompleted} done, ${state.stepsSkipped} skipped, '
          '${state.totalActiveSeconds}s active',
    );
  }

  Future<void> _saveSession(ExecutionState state, {DateTime? endedAt}) async {
    await _sessionRepository.upsert(
      WorkoutSession(
        id: state.sessionId,
        planId: state.plan.id,
        // Snapshotted, so history stays readable after a re-import.
        planName: state.plan.name,
        startedAt: state.startedAt,
        endedAt: endedAt,
        totalActiveSeconds: state.totalActiveSeconds,
        status: switch (state.status) {
          ExecutionStatus.running => null,
          ExecutionStatus.completed => SessionStatus.completed,
          ExecutionStatus.abandoned => SessionStatus.abandoned,
        },
        stepsCompleted: state.stepsCompleted,
        stepsSkipped: state.stepsSkipped,
      ),
    );
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
