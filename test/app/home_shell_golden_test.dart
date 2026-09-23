import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_footer.dart';
import 'package:gimmy/core/widgets/gimmy_scaffold.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/active/view/active_page.dart';
import 'package:gimmy/features/dashboard/view/dashboard_page.dart';
import 'package:gimmy/features/settings/view/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';
import '../support/fake_heart_rate_monitor.dart';
import '../support/sample_fit.dart';

Plan samplePlan() => FitWorkoutParser.parse(
  bytes: sampleFitBytes(),
  filename: sampleFitFilename,
  planId: 'plan-1',
  importedAt: DateTime(2026, 9, 22, 10),
);

/// A short run of sessions ending today, so the streak and the calendar both
/// have something to draw.
List<WorkoutSession> sampleSessions(DateTime today) => [
  for (final offset in [4, 2, 1, 0])
    WorkoutSession(
      id: 's$offset',
      planId: 'plan-1',
      planName: sampleFitPlanName,
      startedAt: DateTime(today.year, today.month, today.day - offset, 18),
      endedAt: DateTime(today.year, today.month, today.day - offset, 19),
      totalActiveSeconds: 3600,
      status: offset == 2 ? SessionStatus.abandoned : SessionStatus.completed,
      stepsCompleted: offset == 2 ? 10 : sampleFitStepCount,
      stepsSkipped: offset == 2 ? 3 : 0,
    ),
];

void main() {
  late Directory tempDir;

  setUpAll(loadAppFonts);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-shell');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<AppBloc> seededBloc({required bool withPlan}) async {
    final planRepository = PlanRepository(
      store: FileDocumentStore('plan.json', directory: tempDir),
    );
    final sessionRepository = SessionRepository(
      store: FileDocumentStore('sessions.json', directory: tempDir),
    );
    final settingsRepository = SettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    );

    if (withPlan) {
      await planRepository.save(samplePlan());
      for (final session in sampleSessions(DateTime.now())) {
        await sessionRepository.upsert(session);
      }
    }

    return AppBloc(
      planRepository: planRepository,
      sessionRepository: sessionRepository,
      settingsRepository: settingsRepository,
    )..add(const AppStarted());
  }

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required GimmyTab tab,
    required Widget page,
    required Brightness brightness,
    bool withPlan = true,
  }) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Seeding touches the real filesystem, and `testWidgets` runs under fake
    // async where dart:io futures never complete. `runAsync` steps outside it.
    late final AppBloc bloc;
    await tester.runAsync(() async {
      bloc = await seededBloc(withPlan: withPlan);
      await bloc.stream.firstWhere((s) => s.status == AppStatus.ready);
    });
    addTearDown(bloc.close);

    await tester.pumpWidget(
      withHeartRate(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: BlocProvider.value(
            value: bloc,
            child: GimmyScaffold(
              label: 'Preview',
              tab: tab,
              onSelectTab: (_) {},
              child: page,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('dashboard with a plan and a live streak (dark)', (tester) async {
    await capture(
      tester,
      name: 'dashboard_dark',
      tab: GimmyTab.dashboard,
      page: const DashboardPage(),
      brightness: Brightness.dark,
    );
  });

  testWidgets('dashboard with a plan and a live streak (light)', (
    tester,
  ) async {
    await capture(
      tester,
      name: 'dashboard_light',
      tab: GimmyTab.dashboard,
      page: const DashboardPage(),
      brightness: Brightness.light,
    );
  });

  testWidgets('active page: start banner above the step list', (tester) async {
    await capture(
      tester,
      name: 'active_dark',
      tab: GimmyTab.active,
      page: const ActivePage(),
      brightness: Brightness.dark,
    );
  });

  testWidgets('active page with no plan imported', (tester) async {
    await capture(
      tester,
      name: 'active_empty_dark',
      tab: GimmyTab.active,
      page: const ActivePage(),
      brightness: Brightness.dark,
      withPlan: false,
    );
  });

  testWidgets('settings, where importing now lives', (tester) async {
    await capture(
      tester,
      name: 'settings_dark',
      tab: GimmyTab.settings,
      page: SettingsPage(onImport: () {}, onWiped: () {}),
      brightness: Brightness.dark,
    );
  });
}
