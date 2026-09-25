import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/streak_calculator.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';

import 'execution_bloc_test.dart' show FakeTicker;
import '../../support/sample_fit.dart';

/// Acceptance: a full run of the real sample plan records a completed session.
void main() {
  late Directory tempDir;
  late SessionRepository sessions;
  late FakeTicker ticker;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-fullrun');
    sessions = SessionRepository(
      store: FileDocumentStore('sessions.json', directory: tempDir),
    );
    ticker = FakeTicker();
  });

  tearDown(() async {
    await ticker.dispose();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Plan sample() => FitWorkoutParser.parse(
    bytes: sampleFitBytes(),
    filename: sampleFitFilename,
    planId: 'plan-1',
    importedAt: DateTime(2026, 9, 22, 10),
  );

  test(
    'every step of the sample can be worked through to a completed session',
    () async {
      final plan = sample();
      final startedAt = DateTime(2026, 9, 22, 18);
      final bloc = ExecutionBloc(
        plan: plan,
        sessionRepository: sessions,
        ticker: ticker,
        now: () => startedAt,
        advanceGuard: Duration.zero,
      )..add(const ExecutionStarted());
      await pumpEventQueue();

      var guard = 0;
      while (bloc.state.isRunning) {
        // Nothing should take this many moves; the guard stops a bug here from
        // hanging the suite instead of failing it.
        expect(
          guard++,
          lessThan(plan.stepCount * 4),
          reason: 'stuck on a step',
        );

        final step = bloc.state.currentStep!;
        if (step.isTimer) {
          bloc.add(const ExecutionPrimaryPressed());
          await pumpEventQueue();
          await ticker.tick(step.durationSeconds!);
        } else {
          bloc.add(const ExecutionPrimaryPressed());
          await pumpEventQueue();
        }
      }

      expect(bloc.state.status, ExecutionStatus.completed);
      expect(bloc.state.stepsCompleted, sampleFitStepCount);
      expect(bloc.state.stepsSkipped, 0);

      // Every timer in the plan, run down in full: 20m15s of actual clock.
      expect(bloc.state.totalActiveSeconds, sampleFitTimerSeconds);

      final stored = await sessions.loadAll();
      expect(stored, hasLength(1), reason: 'one session, written twice');
      expect(stored.single.status, SessionStatus.completed);
      expect(stored.single.stepsCompleted, sampleFitStepCount);
      expect(stored.single.planName, sampleFitPlanName);
      expect(stored.single.endedAt, isNotNull);

      // And the day now counts towards the streak.
      expect(StreakCalculator.calculate(stored, now: startedAt), 1);

      await bloc.close();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
