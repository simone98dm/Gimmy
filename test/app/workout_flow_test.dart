import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/app/view/home_shell.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_until.dart';

/// Acceptance: running a workout to the end records it and the Dashboard
/// reflects it — streak up, marker on today.
///
/// A three-step plan rather than the 54-step sample: the sample is covered at
/// the bloc level, and this is about the wiring between pages.
Plan shortPlan() => Plan(
  id: 'plan-1',
  name: 'Quick Session',
  sourceFilename: 'quick.fit',
  importedAt: DateTime(2026, 9, 22),
  steps: [
    PlanStep.reps(name: 'Squat', intensity: StepIntensity.active, repCount: 10),
    PlanStep.reps(name: 'Row', intensity: StepIntensity.active, repCount: 8),
    PlanStep.open(name: 'Stretch', intensity: StepIntensity.cooldown),
  ],
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-workout');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('running a plan to the end updates the Dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    List<WorkoutSession> stored = const [];

    await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();
      final planRepository = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );
      final sessionRepository = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );
      await planRepository.save(shortPlan());

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: planRepository),
            RepositoryProvider.value(value: sessionRepository),
            RepositoryProvider(
              create: (_) => SettingsRepository(preferences: preferences),
            ),
          ],
          child: BlocProvider(
            create: (context) => AppBloc(
              planRepository: planRepository,
              sessionRepository: sessionRepository,
              settingsRepository: context.read<SettingsRepository>(),
            )..add(const AppStarted()),
            child: MaterialApp(theme: AppTheme.dark, home: const HomeShell()),
          ),
        ),
      );
      // The Dashboard opens with no streak and the plan ready to run.
      await pumpUntilFound(tester, find.text('0 DAYS STREAK'));
      await pumpUntilFound(tester, find.text('START WORKOUT'));

      await tester.tap(find.text('START WORKOUT'));

      // Into the runner, on the first step.
      await pumpUntilFound(tester, find.text('STEP 1 OF 3'));
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Row'), findsOneWidget, reason: 'shown as next up');

      // Reps and open steps advance on Next. The control is icon-only, so it
      // is addressed the way a screen reader would.
      for (var step = 0; step < 3; step++) {
        await tester.tap(find.bySemanticsLabel('Next'));
        await pumpUntil(
          tester,
          () =>
              find.text('STEP ${step + 2} OF 3').evaluate().isNotEmpty ||
              find.text('Workout crushed! 🎉').evaluate().isNotEmpty,
          reason: 'step ${step + 2} or the summary',
        );
      }

      expect(find.text('Workout crushed! 🎉'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget, reason: 'all steps completed');
      expect(find.text('100% completed'), findsOneWidget);

      await tester.tap(find.text('Return to Dashboard'));
      await pumpUntilGone(tester, find.text('Workout crushed! 🎉'));

      // The Dashboard reloads from disk, so this has to be awaited inside
      // `runAsync` — outside it the read would never complete.
      await pumpUntilFound(tester, find.text('1 DAY STREAK'));

      stored = await sessionRepository.loadAll();
    });

    expect(stored, hasLength(1));
    expect(stored.single.status, SessionStatus.completed);
    expect(stored.single.stepsCompleted, 3);
    expect(stored.single.planName, 'Quick Session');
  });
}
