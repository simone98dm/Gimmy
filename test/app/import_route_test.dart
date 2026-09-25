import 'package:gimmy/data/exercises/exercise_demos.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/view/import_route.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/fit/fit_file_picker.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_exercise_demos.dart';
import '../support/sample_fit.dart';

/// Drives the real Import route end to end: pick, preview, confirm, and out.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-route');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<PickedFitFile?> pickSample() async =>
      PickedFitFile(name: sampleFitFilename, bytes: sampleFitBytes());

  /// Pushes [ImportRoute] and records what it pops with.
  Widget harness({
    required bool canPop,
    required void Function(bool?) onResult,
    required SharedPreferences preferences,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => ExerciseDemos(media: FakeExerciseMediaStore()),
        ),
        RepositoryProvider(
          create: (_) => PlanRepository(
            store: FileDocumentStore('plan.json', directory: tempDir),
          ),
        ),
        RepositoryProvider(
          create: (_) => SettingsRepository(preferences: preferences),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                ImportRoute.route(canPop: canPop, pickFile: pickSample),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  /// Pumps enough real time for the bloc's file I/O to land.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  for (final canPop in [true, false]) {
    testWidgets(
      'offers the sample only with no plan behind (canPop: $canPop)',
      (tester) async {
        await tester.runAsync(() async {
          final preferences = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            harness(canPop: canPop, preferences: preferences, onResult: (_) {}),
          );
          await tester.tap(find.text('open'));
          await settle(tester);
        });

        expect(
          find.text('Try a sample workout', skipOffstage: false),
          canPop ? findsNothing : findsOneWidget,
        );
      },
    );
  }

  for (final canPop in [true, false]) {
    testWidgets('confirming an import leaves the page (canPop: $canPop)', (
      tester,
    ) async {
      bool? result;
      var popped = false;
      int? savedSteps;

      await tester.runAsync(() async {
        final preferences = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          harness(
            canPop: canPop,
            preferences: preferences,
            onResult: (value) {
              result = value;
              popped = true;
            },
          ),
        );

        await tester.tap(find.text('open'));
        await settle(tester);

        await tester.tap(find.text('Select .FIT File'));
        await settle(tester);

        // The pinned action bar only exists once a plan has parsed.
        expect(find.text('Confirm & Save Plan'), findsOneWidget);

        // Pinned to the bottom bar, so it needs no scrolling to reach.
        await tester.tap(find.text('Confirm & Save Plan'));
        await settle(tester);

        // Read storage here too: outside `runAsync` the file I/O would never
        // complete and the test would hang rather than fail.
        savedSteps = (await PlanRepository(
          store: FileDocumentStore('plan.json', directory: tempDir),
        ).load())?.stepCount;
      });

      expect(
        popped,
        isTrue,
        reason: 'the route should close itself once the plan is saved',
      );
      expect(result, isTrue, reason: 'it reports that a plan was imported');
      expect(savedSteps, sampleFitStepCount, reason: 'the plan is on disk');
    });
  }
}
