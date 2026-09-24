import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/bloc/ticker.dart';

/// A ticker driven by the test instead of the clock.
class FakeTicker implements Ticker {
  final _controller = StreamController<void>.broadcast();

  @override
  Stream<void> ticks() => _controller.stream;

  /// Advances [seconds] one-second ticks, letting the bloc settle after each.
  Future<void> tick(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      _controller.add(null);
      await pumpEventQueue(times: 5);
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
  late Directory tempDir;
  late SessionRepository sessions;
  late FakeTicker ticker;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-exec');
    sessions = SessionRepository(
      store: FileDocumentStore('sessions.json', directory: tempDir),
    );
    ticker = FakeTicker();
  });

  tearDown(() async {
    await ticker.dispose();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ExecutionBloc blocFor(Plan plan) => ExecutionBloc(
    plan: plan,
    sessionRepository: sessions,
    ticker: ticker,
    now: () => DateTime(2026, 9, 22, 18),
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
      expect(bloc.state.canUndoSkip, isTrue);

      bloc.add(const ExecutionSkipUndone());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Rest');
      expect(bloc.state.remainingSeconds, 60);
      expect(bloc.state.isTimerRunning, isFalse);
      expect(bloc.state.stepsSkipped, 0);
      expect(bloc.state.canUndoSkip, isFalse);
    });

    test('undo is not offered after a step is done normally', () async {
      final bloc = await started(planOf([reps('Squat', 10), reps('Row', 8)]));
      addTearDown(bloc.close);

      bloc.add(const ExecutionPrimaryPressed());
      await pumpEventQueue(times: 50);
      expect(bloc.state.canUndoSkip, isFalse);

      bloc.add(const ExecutionSkipUndone());
      await pumpEventQueue(times: 50);

      expect(bloc.state.currentStep?.name, 'Row');
      expect(bloc.state.stepsCompleted, 1);
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
