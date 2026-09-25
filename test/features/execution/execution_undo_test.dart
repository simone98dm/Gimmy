import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_sidebar.dart';
import 'package:gimmy/core/widgets/gimmy_scaffold.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/view/execution_page.dart';

import '../../support/fake_heart_rate_monitor.dart';
import '../../support/memory_store.dart';
import '../../support/silent_cues.dart';
import 'execution_bloc_test.dart' show FakeTicker, planOf, reps;

void main() {
  silenceWorkoutCues();

  late ExecutionBloc bloc;
  late FakeTicker ticker;

  Future<void> pumpRunner(WidgetTester tester) async {
    // A real phone, not the 800x600 default: where the snackbar lands
    // relative to the controls is part of what is under test.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    ticker = FakeTicker();
    bloc = ExecutionBloc(
      plan: planOf([reps('Squat', 10), reps('Row', 8)]),
      sessionRepository: SessionRepository(store: MemoryStore()),
      ticker: ticker,
      advanceGuard: Duration.zero,
    )..add(const ExecutionStarted());
    addTearDown(() async {
      await bloc.close();
      await ticker.dispose();
    });

    await tester.pumpWidget(
      withHeartRate(
        MaterialApp(
          theme: AppTheme.dark,
          home: BlocProvider.value(
            value: bloc,
            child: GimmyScaffold(
              label: 'Workout',
              extendsToBottomEdge: true, // as ExecutionRoute
              sidebarItem: SidebarItem.active,
              child: ExecutionPage(onDone: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Done names the step and offers it back', (tester) async {
    await pumpRunner(tester);

    await tapDone(tester);
    expect(find.text('Squat done'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(bloc.state.currentStep?.name, 'Squat');
    expect(bloc.state.stepsCompleted, 0);
    expect(find.text('Squat done'), findsNothing);
  });

  testWidgets('the offer stays while time passes', (tester) async {
    await pumpRunner(tester);
    await tapDone(tester);

    // Well past the old 4-second window, with the clock ticking.
    for (var i = 0; i < 3; i++) {
      bloc.add(const ExecutionTicked());
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Squat done'), findsOneWidget);
  });

  testWidgets('Undo on the summary reopens the last step', (tester) async {
    await pumpRunner(tester);
    await tapDone(tester);
    await tapDone(tester);
    expect(find.text('Undo last step'), findsOneWidget);
    expect(find.text('Row done'), findsNothing, reason: 'the summary has it');

    await tester.tap(find.text('Undo last step'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(bloc.state.isRunning, isTrue);
    expect(bloc.state.currentStep?.name, 'Row');
    expect(find.text('Undo last step'), findsNothing);
  });
}
