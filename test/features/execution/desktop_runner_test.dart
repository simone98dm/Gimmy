import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/config/feature_flags.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_sidebar.dart';
import 'package:gimmy/core/widgets/desktop_layout.dart';
import 'package:gimmy/core/widgets/gimmy_scaffold.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/view/execution_page.dart';

import '../../support/fake_exercise_demos.dart';
import '../../support/fake_heart_rate_monitor.dart';
import '../../support/memory_store.dart';
import '../../support/silent_cues.dart';
import 'execution_bloc_test.dart' show FakeTicker, planOf, reps, timer;

void main() {
  silenceWorkoutCues();

  late ExecutionBloc bloc;
  late bool isDone;

  Future<void> pumpDesktop(
    WidgetTester tester,
    List<PlanStep> steps, {
    ExerciseDemos? demos,
  }) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    debugDesktopLayoutEnabled = true;
    addTearDown(() {
      tester.view.reset();
      debugDesktopLayoutEnabled = false;
    });

    isDone = false;
    final ticker = FakeTicker();
    bloc = ExecutionBloc(
      plan: planOf(steps),
      sessionRepository: SessionRepository(store: MemoryStore()),
      ticker: ticker,
      advanceGuard: Duration.zero,
    )..add(const ExecutionStarted());
    addTearDown(() async {
      await bloc.close();
      await ticker.dispose();
    });

    await tester.pumpWidget(
      withExerciseDemos(
        demos: demos,
        withHeartRate(
          MaterialApp(
            theme: AppTheme.dark,
            home: BlocProvider.value(
              value: bloc,
              child: GimmyScaffold(
                label: 'Workout',
                extendsToBottomEdge: true, // as ExecutionRoute
                sidebarItem: SidebarItem.active,
                child: ExecutionPage(onDone: () => isDone = true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Space, S and Ctrl+Z drive the workout', (tester) async {
    await pumpDesktop(tester, [reps('A', 5), reps('B', 5), reps('C', 5)]);

    await press(tester, LogicalKeyboardKey.space);
    expect(bloc.state.currentStep?.name, 'B');

    await press(tester, LogicalKeyboardKey.keyS);
    expect(bloc.state.currentStep?.name, 'C');
    expect(bloc.state.stepsSkipped, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await press(tester, LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(bloc.state.currentStep?.name, 'B');
    expect(bloc.state.stepsSkipped, 0);
  });

  testWidgets('minus takes ten seconds off a timer', (tester) async {
    await pumpDesktop(tester, [timer('Plank', 60)]);
    await press(tester, LogicalKeyboardKey.minus);
    expect(bloc.state.remainingSeconds, 50);
  });

  testWidgets('Enter on the summary goes back to Today', (tester) async {
    await pumpDesktop(tester, [reps('Only', 5)]);
    await press(tester, LogicalKeyboardKey.space);
    expect(bloc.state.isFinished, isTrue);

    // Space does nothing more once it is over.
    await press(tester, LogicalKeyboardKey.space);
    expect(bloc.state.stepsCompleted, 1);

    await press(tester, LogicalKeyboardKey.enter);
    expect(isDone, isTrue);
  });

  testWidgets('the plan list marks each step and follows the current one', (
    tester,
  ) async {
    await pumpDesktop(tester, [
      for (var i = 1; i <= 40; i++) reps('Set $i', 5),
    ]);

    await press(tester, LogicalKeyboardKey.space);
    await press(tester, LogicalKeyboardKey.keyS);
    expect(
      find.bySemanticsLabel('Step 1, Set 1, 5 reps, done'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Step 2, Set 2, 5 reps, skipped'),
      findsOneWidget,
    );

    for (var i = 0; i < 30; i++) {
      await press(tester, LogicalKeyboardKey.space);
    }
    // The scroll starts on the frame after the step changes; give it frames.
    await tester.pump(const Duration(milliseconds: 300));
    // Step 33 is current, far below the first screenful, and in view.
    expect(
      find.bySemanticsLabel('Step 33, Set 33, 5 reps, current').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('each control shows its key and says it', (tester) async {
    await pumpDesktop(tester, [reps('A', 5), reps('B', 5)]);

    expect(find.text('Space · Done'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip this step, S'), findsOneWidget);
    expect(find.text('End'), findsNothing);
  });

  group('exercise demos', () {
    Finder credit() => find.textContaining(AppConfig.exerciseMediaCredit);

    Future<void> settleDemo(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('the demo stands beside the dial, no swipe needed', (
      tester,
    ) async {
      await pumpDesktop(tester, [
        reps('Squat', 10).copyWith(exerciseId: '0001'),
      ], demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])));
      await settleDemo(tester);

      expect(find.byType(PageView), findsNothing);
      expect(credit().hitTestable(), findsOneWidget);
      // Once: the dial already shows it, the demo does not repeat it.
      expect(find.text('×10'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });

    testWidgets('without a demo the dial stands alone', (tester) async {
      await pumpDesktop(tester, [
        reps('Squat', 10),
      ], demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])));
      await settleDemo(tester);

      expect(credit(), findsNothing);
    });

    testWidgets('each step shows its own demo, or none', (tester) async {
      await pumpDesktop(tester, [
        reps('Squat', 10).copyWith(exerciseId: '0001'),
        reps('Stretch', 1),
      ], demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])));
      await settleDemo(tester);
      expect(credit(), findsOneWidget);

      await press(tester, LogicalKeyboardKey.space);
      await settleDemo(tester);

      expect(credit(), findsNothing);
    });
  });
}
