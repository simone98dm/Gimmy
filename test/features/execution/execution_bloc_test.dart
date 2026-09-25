import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/bloc/ticker.dart';

import '../../support/memory_store.dart';

/// A ticker driven by the test instead of the clock.
class FakeTicker implements Ticker {
  final _controller = StreamController<void>.broadcast();

  @override
  Stream<void> ticks() => _controller.stream;

  /// Advances [seconds] one-second ticks, letting the bloc settle after each.
  Future<void> tick(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      _controller.add(null);
      // The bloc handles events one at a time through an async queue, which
      // takes a few more turns to drain than a plain handler.
      await pumpEventQueue(times: 20);
    }
  }

  Future<void> dispose() => _controller.close();
}

Plan planOf(List<PlanStep> steps) => Plan(
  id: 'plan-1',
  name: 'Test Plan',
  sourceFilename: 'test.fit',
  importedAt: DateTime(2026, 9, 22),
  steps: steps,
);

PlanStep timer(String name, int seconds) => PlanStep.timer(
  name: name,
  intensity: StepIntensity.active,
  durationSeconds: seconds,
);

PlanStep reps(String name, int count) =>
    PlanStep.reps(name: name, intensity: StepIntensity.active, repCount: count);

PlanStep open(String name) =>
    PlanStep.open(name: name, intensity: StepIntensity.cooldown);

void main() {
  late MemoryStore store;
  late SessionRepository sessions;
  late FakeTicker ticker;

  setUp(() {
    store = MemoryStore();
    sessions = SessionRepository(store: store);
    ticker = FakeTicker();
  });

  tearDown(() async {
    await ticker.dispose();
  });

  ExecutionBloc blocFor(Plan plan) => ExecutionBloc(
    plan: plan,
    sessionRepository: sessions,
    ticker: ticker,
    now: () => DateTime(2026, 9, 22, 18),
    // The clock above is frozen, so any guard would swallow every second
    // tap. The guard has its own test.
    advanceGuard: Duration.zero,
  );

  Future<ExecutionBloc> started(Plan plan) async {
    final bloc = blocFor(plan)..add(const ExecutionStarted());
    await pumpEventQueue(times: 50);
    return bloc;
  }

  group('starting a workout', () {
    test('opens on the first step with its timer stopped', () async {
      final bloc = await started(
        planOf([timer('Warmup', 60), reps('Squat', 10)]),
      );
      addTearDown(bloc.close);

      expect(bloc.state.currentStep?.name, 'Warmup');
      expect(bloc.state.remainingSeconds, 60);
      expect(bloc.state.isTimerRunning, isFalse);
      expect(bloc.state.primaryAction, PrimaryAction.play);
      expect(bloc.state.stepNumber, 1);
      expect(bloc.state.totalSteps, 2);
    });

    test('records the session immediately, before any step is done', () async {
      final bloc = await started(planOf([timer('Warmup', 60)]));
      addTearDown(bloc.close);

      final stored = await sessions.loadAll();
      expect(stored, hasLength(1));
      expect(stored.single.status, isNull, reason: 'still in progress');
      expect(stored.single.planName, 'Test Plan');
      expect(stored.single.endedAt, isNull);
    });

    test('does not tick until Play is pressed', () async {
      final bloc = await started(planOf([timer('Warmup', 60)]));
      addTearDown(bloc.close);

      await ticker.tick(5);

      expect(bloc.state.remainingSeconds, 60);
      expect(bloc.state.totalActiveSeconds, 0);
    });
  });

  group('timer steps', () {
    test('Play starts the countdown, Pause stops it', () async {
      final bloc = await started(planOf([timer('Plank', 30)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      expect(bloc.state.primaryAction, PrimaryAction.pause);

      await ticker.tick(3);
      expect(bloc.state.remainingSeconds, 27);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      expect(bloc.state.isTimerRunning, isFalse);

      await ticker.tick(5);
      expect(bloc.state.remainingSeconds, 27, reason: 'paused means paused');
    });

    test('advances by itself when the countdown reaches zero', () async {
      final bloc = await started(planOf([timer('Plank', 3), reps('Curl', 12)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(3);

      expect(bloc.state.currentStep?.name, 'Curl');
      expect(bloc.state.stepsCompleted, 1);
      expect(bloc.state.stepsSkipped, 0);
    });

    test('the step it advances to also waits for Play', () async {
      final bloc = await started(planOf([timer('A', 2), timer('B', 60)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(2);

      expect(bloc.state.currentStep?.name, 'B');
      expect(bloc.state.isTimerRunning, isFalse);
      expect(bloc.state.primaryAction, PrimaryAction.play);

      await ticker.tick(5);
      expect(bloc.state.remainingSeconds, 60, reason: 'it never auto-started');
    });
  });

  group('the −10s control', () {
    test('takes ten seconds off a running timer', () async {
      final bloc = await started(planOf([timer('Rest', 60)]));
      addTearDown(bloc.close);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      bloc.add(const ExecutionTimerAdjusted());
      await pumpEventQueue(times: 50);

      expect(bloc.state.remainingSeconds, 50);
    });

    test('works on a paused timer too', () async {
      final bloc = await started(planOf([timer('Rest', 60)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionTimerAdjusted());
      await pumpEventQueue(times: 50);

      expect(bloc.state.remainingSeconds, 50);
    });

    test('never goes below zero — it ends the step instead', () async {
      final bloc = await started(planOf([timer('Rest', 6), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionTimerAdjusted());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Row');
      expect(bloc.state.stepsCompleted, 1);
      expect(
        bloc.state.stepsSkipped,
        0,
        reason: 'running a timer down is finishing it, not skipping it',
      );
    });

    test('is unavailable on a reps step', () async {
      final bloc = await started(planOf([reps('Row', 8)]));
      addTearDown(bloc.close);

      expect(bloc.state.canAdjustTimer, isFalse);

      bloc.add(const ExecutionTimerAdjusted());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Row', reason: 'nothing happened');
      expect(bloc.state.stepsCompleted, 0);
    });
  });

  group('reps and open steps', () {
    test('show Next and advance only when it is pressed', () async {
      final bloc = await started(
        planOf([reps('Squat', 12), timer('Rest', 60)]),
      );
      addTearDown(bloc.close);

      expect(bloc.state.primaryAction, PrimaryAction.next);

      await ticker.tick(10);
      expect(bloc.state.currentStep?.name, 'Squat', reason: 'no clock on reps');

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Rest');
      expect(bloc.state.stepsCompleted, 1);
    });

    test('an open step behaves like a reps step', () async {
      final bloc = await started(planOf([open('Stretch'), reps('Row', 8)]));
      addTearDown(bloc.close);

      expect(bloc.state.primaryAction, PrimaryAction.next);
      expect(bloc.state.canAdjustTimer, isFalse);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Row');
    });

    test('time spent on a reps step still counts as active', () async {
      final bloc = await started(planOf([reps('Squat', 12)]));
      addTearDown(bloc.close);

      await ticker.tick(7);

      expect(bloc.state.totalActiveSeconds, 7);
    });
  });

  group('skipping', () {
    test('moves on and records the step as skipped', () async {
      final bloc = await started(planOf([timer('Rest', 60), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Row');
      expect(bloc.state.stepsSkipped, 1);
      expect(bloc.state.stepsCompleted, 0);
    });

    test('skipping the last step still finishes the workout', () async {
      final bloc = await started(planOf([reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);

      expect(bloc.state.status, ExecutionStatus.completed);
      expect(bloc.state.stepsSkipped, 1);
    });

    test('undo returns to the skipped step with its timer reset', () async {
      final bloc = await started(planOf([timer('Rest', 60), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);
      expect(bloc.state.canUndo, isTrue);

      bloc.add(const ExecutionUndone());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Rest');
      expect(bloc.state.remainingSeconds, 60);
      expect(bloc.state.isTimerRunning, isFalse);
      expect(bloc.state.stepsSkipped, 0);
      expect(bloc.state.canUndo, isFalse);
    });

    test('undo takes back a step marked done, and its count', () async {
      final bloc = await started(planOf([reps('Squat', 10), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      expect(bloc.state.lastAdvance, AdvanceKind.done);
      expect(bloc.state.undoableStep?.name, 'Squat');

      bloc.add(const ExecutionUndone());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Squat');
      expect(bloc.state.stepsCompleted, 0);
      expect(bloc.state.canUndo, isFalse);
    });

    test('undo stays on offer until the next action, then goes', () async {
      final bloc = await started(
        planOf([reps('Squat', 10), timer('Rest', 60), reps('Row', 8)]),
      );
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(3);
      expect(bloc.state.canUndo, isTrue, reason: 'time passing is no action');

      bloc.add(const ExecutionPrimaryPressed()); // Play on Rest
      await pumpEventQueue(times: 50);
      expect(bloc.state.canUndo, isFalse);
    });

    test('a timer running out is not undoable', () async {
      final bloc = await started(planOf([timer('Plank', 2), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(2);

      expect(bloc.state.currentStep?.name, 'Row');
      expect(bloc.state.canUndo, isFalse);
    });

    test('undo on the last step reopens the finished workout', () async {
      final bloc = await started(planOf([reps('Squat', 10), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      // Finishing and reopening both write to disk: wait for the state, not
      // for a count of turns.
      final finished = bloc.stream.firstWhere((s) => s.isFinished);
      bloc.add(const ExecutionPrimaryPressed());
      await finished;
      expect(bloc.state.status, ExecutionStatus.completed);
      expect(bloc.state.canUndo, isTrue);

      final reopened = bloc.stream.firstWhere((s) => s.isRunning);
      bloc.add(const ExecutionUndone());
      await reopened;

      expect(bloc.state.status, ExecutionStatus.running);
      expect(bloc.state.currentStep?.name, 'Row');
      expect(bloc.state.stepsCompleted, 1);

      final stored = (await sessions.loadAll()).single;
      expect(stored.status, isNull, reason: 'in progress again');
      expect(stored.endedAt, isNull);

      // The clock is back on: a reps step counts its time.
      final active = bloc.state.totalActiveSeconds;
      await ticker.tick(2);
      expect(bloc.state.totalActiveSeconds, active + 2);
    });
  });

  group('step records', () {
    Future<WorkoutSession> stored() async => (await sessions.loadAll()).single;

    test('each step is recorded as it is left, then saved', () async {
      final bloc = await started(
        planOf([reps('Squat', 10), timer('Plank', 2), reps('Row', 8)]),
      );
      addTearDown(bloc.close);

      await ticker.tick(3); // three seconds of squats
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      // Saved as it goes, not only at the end.
      expect((await stored()).steps.map((r) => r.name), ['Squat']);
      expect((await stored()).isFinished, isFalse);

      bloc.add(const ExecutionPrimaryPressed()); // Play
      await pumpEventQueue(times: 50);
      await ticker.tick(2); // runs out
      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);

      final session = await stored();
      expect(session.plannedSteps, 3);
      expect(session.steps, [
        const StepRecord(
          name: 'Squat',
          target: '10 reps',
          intensity: StepIntensity.active,
          outcome: StepOutcome.done,
          activeSeconds: 3,
        ),
        const StepRecord(
          name: 'Plank',
          target: '00:02',
          intensity: StepIntensity.active,
          outcome: StepOutcome.done,
          activeSeconds: 2,
        ),
        const StepRecord(
          name: 'Row',
          target: '8 reps',
          intensity: StepIntensity.active,
          outcome: StepOutcome.skipped,
          activeSeconds: 0,
        ),
      ]);
    });

    test('an early exit leaves the unreached steps counted', () async {
      final bloc = await started(
        planOf([reps('A', 5), reps('B', 5), reps('C', 5)]),
      );
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      bloc.add(const ExecutionAbandoned());
      await pumpEventQueue(times: 50);

      final session = await stored();
      expect(session.steps, hasLength(1));
      expect(session.stepsNotReached, 2);
    });

    test('undo takes the record back, keeping the time worked', () async {
      final bloc = await started(planOf([reps('Squat', 10), reps('Row', 8)]));
      addTearDown(bloc.close);

      await ticker.tick(4);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      bloc.add(const ExecutionUndone());
      await pumpEventQueue(times: 50);
      expect((await stored()).steps, isEmpty);

      await ticker.tick(2);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      expect((await stored()).steps.single.activeSeconds, 6);
    });

    test('heart rate is averaged per step and over the session', () async {
      int? bpm = 100;
      final bloc = ExecutionBloc(
        plan: planOf([reps('Squat', 10), reps('Row', 8)]),
        sessionRepository: sessions,
        ticker: ticker,
        now: () => DateTime(2026, 9, 22, 18),
        advanceGuard: Duration.zero,
        heartRate: () => bpm,
      )..add(const ExecutionStarted());
      addTearDown(bloc.close);
      await pumpEventQueue(times: 50);

      await ticker.tick(1); // 100
      bpm = 120;
      await ticker.tick(1); // 120
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      bpm = 170;
      await ticker.tick(1); // 170
      bpm = null; // sensor dropped out: no sample, not a zero
      await ticker.tick(1);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      final session = await stored();
      expect(session.steps.map((r) => r.averageBpm), [110, 170]);
      expect(session.averageBpm, 130);
      expect(session.maxBpm, 170);
    });

    test('with no sensor, no heart rate is recorded', () async {
      final bloc = await started(planOf([reps('Squat', 10)]));
      addTearDown(bloc.close);
      await ticker.tick(2);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      final session = await stored();
      expect(session.averageBpm, isNull);
      expect(session.steps.single.averageBpm, isNull);
    });
  });

  group('past outcomes', () {
    test('track done and skipped for the plan list, undo included', () async {
      final bloc = await started(
        planOf([reps('A', 5), reps('B', 5), reps('C', 5)]),
      );
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);
      expect(bloc.state.pastOutcomes, [StepOutcome.done, StepOutcome.skipped]);

      bloc.add(const ExecutionUndone());
      await pumpEventQueue(times: 50);
      expect(bloc.state.pastOutcomes, [StepOutcome.done]);
    });
  });

  group('double taps', () {
    test('a double Done on the last step finishes once', () async {
      final slowStore = MemoryStore(isWriteSlow: true);
      final bloc = ExecutionBloc(
        plan: planOf([reps('Only', 5)]),
        sessionRepository: SessionRepository(store: slowStore),
        ticker: ticker,
        advanceGuard: Duration.zero,
      )..add(const ExecutionStarted());
      addTearDown(bloc.close);
      await pumpEventQueue(times: 50);
      final writesBefore = slowStore.writes;

      // Back to back: the second arrives while the finish is still saving.
      bloc
        ..add(const ExecutionPrimaryPressed())
        ..add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 200);

      expect(bloc.state.status, ExecutionStatus.completed);
      expect(bloc.state.stepsCompleted, 1);
      expect(
        slowStore.writes - writesBefore,
        1,
        reason: 'one finish, one save',
      );
    });

    test('a second tap inside the guard moves nothing', () async {
      var clock = DateTime(2026, 9, 22, 18);
      final bloc = ExecutionBloc(
        plan: planOf([reps('A', 5), reps('B', 5), reps('C', 5)]),
        sessionRepository: sessions,
        ticker: ticker,
        now: () => clock,
        advanceGuard: const Duration(milliseconds: 500),
      )..add(const ExecutionStarted());
      addTearDown(bloc.close);
      await pumpEventQueue(times: 50);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      clock = clock.add(const Duration(milliseconds: 120));
      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'B');
      expect(bloc.state.stepsSkipped, 0);

      clock = clock.add(const Duration(milliseconds: 600));
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      expect(bloc.state.currentStep?.name, 'C');
    });
  });

  group('finishing', () {
    test('completes after the last step and saves the session', () async {
      final bloc = await started(planOf([timer('A', 2), reps('B', 5)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(2);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      expect(bloc.state.status, ExecutionStatus.completed);
      expect(bloc.state.stepsCompleted, 2);

      final stored = await sessions.loadAll();
      expect(stored, hasLength(1), reason: 'the same session, updated');
      expect(stored.single.status, SessionStatus.completed);
      expect(stored.single.endedAt, isNotNull);
      expect(stored.single.stepsCompleted, 2);
    });

    test('stops ticking once finished', () async {
      final bloc = await started(planOf([reps('Only', 5)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      final activeAtFinish = bloc.state.totalActiveSeconds;

      await ticker.tick(5);

      expect(bloc.state.totalActiveSeconds, activeAtFinish);
    });

    test('ignores further input once finished', () async {
      final bloc = await started(planOf([reps('Only', 5)]));
      addTearDown(bloc.close);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      bloc.add(const ExecutionPrimaryPressed());
      bloc.add(const ExecutionSkipped());
      await pumpEventQueue(times: 50);

      expect(bloc.state.stepsCompleted, 1);
      expect(bloc.state.stepsSkipped, 0);
    });

    test('abandoning saves the session as abandoned, mid-plan', () async {
      final bloc = await started(planOf([timer('A', 60), reps('B', 5)]));
      addTearDown(bloc.close);
      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(4);

      bloc.add(const ExecutionAbandoned());
      await pumpEventQueue(times: 50);

      expect(bloc.state.status, ExecutionStatus.abandoned);

      final stored = await sessions.loadAll();
      expect(stored.single.status, SessionStatus.abandoned);
      expect(stored.single.totalActiveSeconds, 4);
      expect(stored.single.endedAt, isNotNull);
    });
  });

  group('progress reporting', () {
    test('counts steps from one', () async {
      final bloc = await started(
        planOf([reps('A', 5), reps('B', 5), reps('C', 5)]),
      );
      addTearDown(bloc.close);

      expect(bloc.state.stepNumber, 1);
      expect(bloc.state.nextStep?.name, 'B');

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);

      expect(bloc.state.stepNumber, 2);
      expect(bloc.state.nextStep?.name, 'C');
    });

    test('has no next step on the last one', () async {
      final bloc = await started(planOf([reps('Only', 5)]));
      addTearDown(bloc.close);

      expect(bloc.state.nextStep, isNull);
    });

    test('timer progress runs from full to empty', () async {
      final bloc = await started(planOf([timer('Plank', 10)]));
      addTearDown(bloc.close);
      expect(bloc.state.timerProgress, 1.0);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      await ticker.tick(5);

      expect(bloc.state.timerProgress, 0.5);
    });

    test('a reps step reports no timer progress', () async {
      final bloc = await started(planOf([reps('Row', 8)]));
      addTearDown(bloc.close);

      expect(bloc.state.timerProgress, 0);
    });
  });
}
