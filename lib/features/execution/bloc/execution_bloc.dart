import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/util/step_target.dart';
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
/// * Done and Skip can be undone until the next action — the last step too,
///   which reopens the finished workout. A timer running out cannot.
/// * Events are handled one at a time, in order, so a second tap can never
///   act on a state the first one is still saving. A Done or Skip inside
///   [AppConfig.advanceGuard] of the previous move is a double tap: ignored.
/// * The session is written the moment the page opens, because that is what
///   makes the day count towards the streak, and rewritten when it ends.
class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  ExecutionBloc({
    required Plan plan,
    required SessionRepository sessionRepository,
    Ticker ticker = const Ticker(),
    DateTime Function() now = DateTime.now,
    Duration advanceGuard = AppConfig.advanceGuard,
    int? Function() heartRate = _noHeartRate,
  }) : _sessionRepository = sessionRepository,
       _heartRate = heartRate,
       _ticker = ticker,
       _now = now,
       _advanceGuard = advanceGuard,
       super(
         ExecutionState(
           plan: plan,
           sessionId: 'session-${now().microsecondsSinceEpoch}',
           startedAt: now(),
           remainingSeconds: plan.steps.first.durationSeconds ?? 0,
         ),
       ) {
    // One handler, one queue: separate `on<>` registrations would each get
    // their own queue and still run side by side.
    on<ExecutionEvent>(_onEvent, transformer: _sequential);
  }

  static Stream<E> _sequential<E>(Stream<E> events, EventMapper<E> mapper) =>
      events.asyncExpand(mapper);

  Future<void> _onEvent(ExecutionEvent event, Emitter<ExecutionState> emit) =>
      switch (event) {
        ExecutionStarted() => _onStarted(event, emit),
        ExecutionPrimaryPressed() => _onPrimaryPressed(event, emit),
        ExecutionSkipped() => _onSkipped(event, emit),
        ExecutionUndone() => _onUndone(event, emit),
        ExecutionTimerAdjusted() => _onTimerAdjusted(event, emit),
        ExecutionTicked() => _onTicked(event, emit),
        ExecutionAbandoned() => _onAbandoned(event, emit),
      };

  final SessionRepository _sessionRepository;
  final Ticker _ticker;
  final DateTime Function() _now;
  final Duration _advanceGuard;

  /// When the workout last moved on, for telling a double tap from two taps.
  DateTime? _lastAdvanceAt;

  /// The paired sensor's latest reading, or null with no sensor or no signal.
  final int? Function() _heartRate;
  static int? _noHeartRate() => null;

  // What the session record is built from. Kept here rather than in the state:
  // the screen never shows them, only the saved history does.
  List<StepRecord> _records = const [];
  int _stepSeconds = 0;
  _BpmTally _stepBpm = const _BpmTally();
  _BpmTally _sessionBpm = const _BpmTally();

  /// One second of work on the current step, with a heart-rate sample if the
  /// sensor has one. A missing reading is no sample, not a zero.
  void _countSecond() {
    _stepSeconds++;
    final bpm = _heartRate();
    if (bpm == null) return;
    _stepBpm = _stepBpm.add(bpm);
    _sessionBpm = _sessionBpm.add(bpm);
  }

  bool get _isDoubleTap {
    final last = _lastAdvanceAt;
    return last != null && _now().difference(last) < _advanceGuard;
  }

  StreamSubscription<void>? _tickerSubscription;

  Future<void> _onStarted(
    ExecutionStarted event,
    Emitter<ExecutionState> emit,
  ) async {
    // Written before anything else happens: opening the page is what counts.
    await _saveSession(state);
    _listenToTicker();
  }

  void _listenToTicker() {
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
        emit(state.copyWith(isTimerRunning: true, clearLastAdvance: true));
      case PrimaryAction.pause:
        emit(state.copyWith(isTimerRunning: false, clearLastAdvance: true));
      case PrimaryAction.next:
        if (_isDoubleTap) return;
        await _advance(emit, skipped: false, by: AdvanceKind.done);
    }
  }

  Future<void> _onSkipped(
    ExecutionSkipped event,
    Emitter<ExecutionState> emit,
  ) async {
    if (state.isFinished || _isDoubleTap) return;
    await _advance(emit, skipped: true, by: AdvanceKind.skipped);
  }

  Future<void> _onUndone(
    ExecutionUndone event,
    Emitter<ExecutionState> emit,
  ) async {
    final kind = state.lastAdvance;
    if (kind == null || state.status == ExecutionStatus.abandoned) return;

    final previous = state.currentIndex - 1;
    final wasFinished = state.isFinished;
    final restored = state.copyWith(
      currentIndex: previous,
      remainingSeconds: state.plan.steps[previous].durationSeconds ?? 0,
      isTimerRunning: false,
      stepsCompleted: state.stepsCompleted - (kind == AdvanceKind.done ? 1 : 0),
      stepsSkipped: state.stepsSkipped - (kind == AdvanceKind.skipped ? 1 : 0),
      status: ExecutionStatus.running,
      clearLastAdvance: true,
      pastOutcomes: state.pastOutcomes.sublist(
        0,
        state.pastOutcomes.length - 1,
      ),
    );
    _lastAdvanceAt = null;

    // The step is back in play, and so is the time already worked on it.
    // ponytail: its heart-rate samples restart; the session's keep them.
    final taken = _records.last;
    _records = _records.sublist(0, _records.length - 1);
    _stepSeconds = taken.activeSeconds;
    _stepBpm = const _BpmTally();

    if (wasFinished) {
      // Back to in progress on disk as well, before the summary goes away.
      await _saveSession(restored);
      _listenToTicker();
      AppLog.info('workout', 'reopened "${state.plan.name}" from the summary');
      emit(restored);
      return;
    }
    emit(restored);
    await _saveSession(restored);
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

    emit(state.copyWith(remainingSeconds: remaining, clearLastAdvance: true));
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
    _countSecond();

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

    final abandoned = state.copyWith(
      status: ExecutionStatus.abandoned,
      clearLastAdvance: true,
    );
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
    AdvanceKind? by,
  }) async {
    final current = state ?? this.state;
    _lastAdvanceAt = _now();

    final step = current.currentStep!;
    _records = [
      ..._records,
      StepRecord(
        name: step.name,
        target: stepTarget(step),
        intensity: step.intensity,
        outcome: skipped ? StepOutcome.skipped : StepOutcome.done,
        activeSeconds: _stepSeconds,
        averageBpm: _stepBpm.average,
      ),
    ];
    _stepSeconds = 0;
    _stepBpm = const _BpmTally();

    final tallied = current.copyWith(
      stepsCompleted: current.stepsCompleted + (skipped ? 0 : 1),
      stepsSkipped: current.stepsSkipped + (skipped ? 1 : 0),
      pastOutcomes: [
        ...current.pastOutcomes,
        skipped ? StepOutcome.skipped : StepOutcome.done,
      ],
      // Only a tap is undoable; [by] is null when a timer ran out.
      lastAdvance: by,
      clearLastAdvance: by == null,
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

    final moved = tallied.copyWith(
      currentIndex: nextIndex,
      remainingSeconds: tallied.plan.steps[nextIndex].durationSeconds ?? 0,
      // The next timer waits for Play too.
      isTimerRunning: false,
    );
    emit(moved);
    // Saved step by step, so a workout cut short by a crash or a killed app
    // still shows what was done.
    await _saveSession(moved);
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

  Future<void> _saveSession(ExecutionState state, {DateTime? endedAt}) =>
      _sessionRepository.upsert(_sessionFor(state, endedAt: endedAt));

  /// The session as it stands now, as it would be saved: what the summary
  /// compares with the last run of this plan.
  WorkoutSession get session => _sessionFor(state);

  WorkoutSession _sessionFor(ExecutionState state, {DateTime? endedAt}) =>
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
        plannedSteps: state.totalSteps,
        steps: _records,
        averageBpm: _sessionBpm.average,
        maxBpm: _sessionBpm.max,
      );

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}

/// Running heart-rate figures, built one sample at a time.
@immutable
class _BpmTally {
  const _BpmTally({this.sum = 0, this.count = 0, this.max});

  final int sum;
  final int count;
  final int? max;

  _BpmTally add(int bpm) => _BpmTally(
    sum: sum + bpm,
    count: count + 1,
    max: max == null || bpm > max! ? bpm : max,
  );

  int? get average => count == 0 ? null : (sum / count).round();
}
