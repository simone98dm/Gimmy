import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/app/view/home_shell.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_footer.dart';
import 'package:gimmy/core/widgets/app_sidebar.dart';
import 'package:gimmy/core/widgets/desktop_layout.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_heart_rate_monitor.dart';
import '../support/pump_until.dart';
import '../support/sample_fit.dart';

/// On a desktop browser the bottom nav becomes a sidebar that also reaches
/// Import, and leaving Import through it lands where it was asked to.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-desktop');
    SharedPreferences.setMockInitialValues({});
    debugDesktopLayoutEnabled = true;
  });

  tearDown(() {
    debugDesktopLayoutEnabled = false;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  SidebarItem current(WidgetTester tester) =>
      tester.widget<AppSidebar>(find.byType(AppSidebar).hitTestable()).current;

  testWidgets('the sidebar switches tabs and leaves Import for a tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final planRepository = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );
      await planRepository.save(
        FitWorkoutParser.parse(
          bytes: sampleFitBytes(),
          filename: sampleFitFilename,
          planId: 'plan-1',
          importedAt: DateTime(2026, 9, 22, 10),
        ),
      );
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: planRepository),
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
              MaterialApp(theme: AppTheme.dark, home: const HomeShell()),
            ),
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('START WORKOUT'));
      expect(find.byType(AppFooter), findsNothing);
      expect(current(tester), SidebarItem.dashboard);

      await tester.tap(find.text('Settings').hitTestable());
      await pumpUntil(tester, () => current(tester) == SidebarItem.settings);

      await tester.tap(find.text('Import plan').hitTestable());
      await pumpUntilFound(tester, find.text('Import a workout'));
      expect(current(tester), SidebarItem.import);

      await tester.tap(find.text('Workout').hitTestable());
      await pumpUntilGone(tester, find.text('Import a workout'));
    });

    expect(current(tester), SidebarItem.active);
  });
}
