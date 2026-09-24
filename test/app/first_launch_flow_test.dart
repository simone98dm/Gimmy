import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/app/view/home_shell.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/fit/fit_file_picker.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_until.dart';
import '../support/fake_heart_rate_monitor.dart';
import '../support/sample_fit.dart';

/// The whole first run: empty install, import, land on the Dashboard.
///
/// This is the seam that broke — the import saved the plan but the page stayed
/// on screen, because `PopScope(canPop: false)` refused the `maybePop` that was
/// meant to close it.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-first-run');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<PickedFitFile?> pickSample() async =>
      PickedFitFile(name: sampleFitFilename, bytes: sampleFitBytes());

  testWidgets('a fresh install imports a plan and lands on the Dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider(
              create: (_) => PlanRepository(
                store: FileDocumentStore('plan.json', directory: tempDir),
              ),
            ),
            RepositoryProvider(
              create: (_) => SessionRepository(
                store: FileDocumentStore('sessions.json', directory: tempDir),
              ),
            ),
            RepositoryProvider(
              create: (_) => SettingsRepository(preferences: preferences),
            ),
          ],
          child: BlocProvider(
            create: (context) => AppBloc(
              planRepository: context.read<PlanRepository>(),
              sessionRepository: context.read<SessionRepository>(),
              settingsRepository: context.read<SettingsRepository>(),
            )..add(const AppStarted()),
            child: withHeartRate(
              MaterialApp(
                theme: AppTheme.dark,
                home: HomeShell(pickFile: pickSample),
              ),
            ),
          ),
        ),
      );
      // With nothing stored, Import opens by itself and cannot be dismissed.
      await pumpUntilFound(tester, find.text('Import a workout'));
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.text('Select .FIT File'));
      await pumpUntilFound(tester, find.text('Confirm & Save Plan'));

      await tester.tap(find.text('Confirm & Save Plan'));
      await pumpUntilGone(tester, find.text('Import a workout'));
    });

    // The import page is gone and the Dashboard is showing. There is no page
    // heading to assert on — the prototype opens straight into the streak —
    // so this checks the things the Dashboard is actually made of.
    expect(find.text('Import a workout'), findsNothing);
    expect(find.text('START A STREAK TODAY'), findsOneWidget);
    expect(find.text(sampleFitPlanName), findsOneWidget);
    expect(find.text('START WORKOUT'), findsOneWidget);
  });
}
