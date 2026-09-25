// Every test here ends in a golden, which lives only on this machine.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_sidebar.dart';
import 'package:gimmy/core/widgets/desktop_layout.dart';
import 'package:gimmy/core/widgets/gimmy_scaffold.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/fit/fit_file_picker.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/import/bloc/import_bloc.dart';
import 'package:gimmy/features/import/view/import_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_exercise_demos.dart';
import '../../support/test_fonts.dart';
import '../../support/sample_fit.dart';

/// Renders the Import page against the real sample workout so its layout can be
/// eyeballed next to the Stitch screen, and regressions show up as a diff.
///
/// Run `flutter test --update-goldens` to refresh after an intentional change.
Plan sampleParsedPlan() => FitWorkoutParser.parse(
  bytes: sampleFitBytes(),
  filename: sampleFitFilename,
  planId: 'plan-1',
  importedAt: DateTime(2026, 9, 22, 10),
);

Widget harness({
  required Brightness brightness,
  required ImportBloc bloc,
  required ExerciseDemos demos,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: GimmyScaffold(
      label: 'Import plan',
      sidebarItem: SidebarItem.import,
      // First run, the state the idle page is mostly seen in: the sample
      // workout is on offer under the picker.
      child: withExerciseDemos(
        demos: demos,
        BlocProvider.value(
          value: bloc,
          child: const ImportPage(offerSample: true),
        ),
      ),
    ),
  );
}

void main() {
  late Directory tempDir;
  late ExerciseCatalog catalog;
  late ExerciseDemos demos;

  setUpAll(() async {
    await loadAppFonts();
    // Read here, outside fake async, where the asset read can complete.
    catalog = await ExerciseCatalog.load(rootBundle);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gimmy-golden');
    SharedPreferences.setMockInitialValues({});
    demos = ExerciseDemos(
      media: FakeExerciseMediaStore(),
      loadCatalog: () async => catalog,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<ImportBloc> blocWith(PickedFitFile? picked) async => ImportBloc(
    pickFile: () async => picked,
    planRepository: PlanRepository(
      store: FileDocumentStore('plan.json', directory: tempDir),
    ),
    settingsRepository: SettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    ),
    demos: demos,
  );

  Future<void> renderAndCapture(
    WidgetTester tester, {
    required Brightness brightness,
    required String name,
    ImportEvent? event,
    bool desktop = false,
  }) async {
    if (desktop) {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      debugDesktopLayoutEnabled = true;
      addTearDown(() => debugDesktopLayoutEnabled = false);
    } else {
      tester.view.physicalSize = const Size(1179, 2556); // iPhone 17
      tester.view.devicePixelRatio = 3;
    }
    addTearDown(tester.view.reset);

    final bloc = await blocWith(
      PickedFitFile(name: sampleFitFilename, bytes: sampleFitBytes()),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      harness(brightness: brightness, bloc: bloc, demos: demos),
    );
    if (event != null) {
      bloc.add(event);
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('import page, waiting for a file (dark)', (tester) async {
    await renderAndCapture(
      tester,
      brightness: Brightness.dark,
      name: 'import_idle_dark',
    );
  });

  testWidgets('import page, waiting for a file (light)', (tester) async {
    await renderAndCapture(
      tester,
      brightness: Brightness.light,
      name: 'import_idle_light',
    );
  });

  testWidgets('import page, previewing the sample plan (dark)', (tester) async {
    await renderAndCapture(
      tester,
      brightness: Brightness.dark,
      name: 'import_preview_dark',
      event: const ImportFileRequested(),
    );
  });

  testWidgets('import page, previewing the sample plan (light)', (
    tester,
  ) async {
    await renderAndCapture(
      tester,
      brightness: Brightness.light,
      name: 'import_preview_light',
      event: const ImportFileRequested(),
    );
  });

  testWidgets('desktop: picker beside the parsed steps', (tester) async {
    await renderAndCapture(
      tester,
      brightness: Brightness.dark,
      name: 'import_preview_desktop_dark',
      event: const ImportFileRequested(),
      desktop: true,
    );
  });
}
