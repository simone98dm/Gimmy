import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/config/feature_flags.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/exercises/exercise_matcher.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/import/bloc/import_bloc.dart';
import 'package:gimmy/features/import/widgets/exercise_demos_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_exercise_demos.dart';
import '../../support/memory_store.dart';

void main() {
  late ExerciseCatalog catalog;

  // Read outside fake async, where the asset read can complete.
  setUpAll(() async => catalog = await ExerciseCatalog.load(rootBundle));

  /// The card over the built-in sample (Squat, Push-up, Plank), previewed.
  Future<ImportBloc> pumpCard(
    WidgetTester tester, {
    bool isEnabled = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final demos = ExerciseDemos(
      isEnabled: isEnabled,
      media: FakeExerciseMediaStore(),
      loadCatalog: () async => catalog,
    );
    final bloc = ImportBloc(
      pickFile: () async => null,
      planRepository: PlanRepository(store: MemoryStore()),
      settingsRepository: SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      ),
      demos: demos,
    )..add(const ImportSampleRequested());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: withExerciseDemos(
            demos: demos,
            BlocProvider.value(
              value: bloc,
              child: BlocBuilder<ImportBloc, ImportState>(
                builder: (context, state) => SingleChildScrollView(
                  child: state.plan == null
                      ? const SizedBox()
                      : ExerciseDemosCard(plan: state.plan!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('shows each exercise with its matched demo and the credit', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text(matchExercise('Squat', catalog)!.name), findsOneWidget);
    expect(find.text('Push-up'), findsOneWidget);
    expect(find.text('push-up'), findsOneWidget);
    expect(find.textContaining(AppConfig.exerciseMediaCredit), findsOneWidget);
  });

  testWidgets('picking another demo changes that exercise', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.bySemanticsLabel('Change the demo for Squat'));
    await tester.pumpAndSettle();

    // The search starts on the step's own name.
    expect(find.text('Demo for Squat'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'sissy squat');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'sissy squat'));
    await tester.pumpAndSettle();

    expect(find.text('Demo for Squat'), findsNothing);
    expect(find.text('sissy squat'), findsOneWidget);
  });

  testWidgets('"No demo" takes it away', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.bySemanticsLabel('Change the demo for Push-up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No demo'));
    await tester.pumpAndSettle();

    expect(find.text('push-up'), findsNothing);
    expect(find.text('No demo'), findsOneWidget);
  });

  testWidgets('dismissing the sheet keeps the demo', (tester) async {
    final bloc = await pumpCard(tester);
    final before = bloc.state.plan;

    await tester.tap(find.bySemanticsLabel('Change the demo for Squat'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(bloc.state.plan, before);
  });

  testWidgets('stays hidden while demos are switched off', (tester) async {
    await pumpCard(tester, isEnabled: false);

    expect(find.text('Exercise demos'), findsNothing);
  });
}
