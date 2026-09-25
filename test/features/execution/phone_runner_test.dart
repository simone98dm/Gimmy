import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_sidebar.dart';
import 'package:gimmy/core/config/feature_flags.dart';
import 'package:gimmy/core/widgets/gimmy_scaffold.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/view/execution_page.dart';
import 'package:gimmy/features/execution/widgets/timer_ring.dart';

import '../../support/fake_exercise_demos.dart';
import '../../support/fake_heart_rate_monitor.dart';
import '../../support/memory_store.dart';
import '../../support/silent_cues.dart';
import 'execution_bloc_test.dart' show FakeTicker, planOf, timer;

void main() {
  silenceWorkoutCues();

  late ExecutionBloc bloc;

  final squat = PlanStep.reps(
    name: 'Back squat with a long name that wraps',
    intensity: StepIntensity.active,
    repCount: 10,
    notes:
        'Feet shoulder-width, chest up, knees tracking over toes, brace '
        'before each rep and drive through the whole foot on the way up.',
  );

  Future<void> pumpRunner(
    WidgetTester tester, {
    required List<PlanStep> steps,
    Size size = const Size(1179, 2556),
    double devicePixelRatio = 3,
    double textScale = 1,
    List<WorkoutSession> history = const [],
    double bottomInset = 0,
    bool viaRoute = false,
    ExerciseDemos? demos,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.padding = FakeViewPadding(
      bottom: bottomInset * devicePixelRatio,
    );
    tester.view.viewPadding = FakeViewPadding(
      bottom: bottomInset * devicePixelRatio,
    );
    addTearDown(tester.view.reset);

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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: reduceMotion,
              ),
              child: child!,
            ),
            home: BlocProvider.value(
              value: bloc,
              child: GimmyScaffold(
                label: 'Workout',
                extendsToBottomEdge: true, // as ExecutionRoute
                sidebarItem: SidebarItem.active,
                child: ExecutionPage(onDone: () {}, history: history),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder control(String label) => find.bySemanticsLabel(label).hitTestable();

  testWidgets(
    'controls stay reachable on a short phone, 2x text, tip open, undo up',
    (tester) async {
      // An iPhone SE: 375x667 points.
      await pumpRunner(
        tester,
        steps: [squat, squat, timer('Rest', 60)],
        size: const Size(750, 1334),
        devicePixelRatio: 2,
        textScale: 2,
      );

      await tester.tap(find.text('Form tip'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(control('Done'), findsOneWidget);

      await tester.tap(control('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The undo snackbar is up, and the controls are still under a thumb.
      expect(find.text('Undo'), findsOneWidget);
      expect(control('Done'), findsOneWidget);
      expect(control('Skip this step'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the ring is drawn only for a countdown', (tester) async {
    await pumpRunner(tester, steps: [squat, timer('Rest', 60)]);
    expect(find.byType(TimerRing), findsNothing);
    expect(find.text('×10'), findsOneWidget);

    await tester.tap(control('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TimerRing), findsOneWidget);
  });

  testWidgets('a form tip opened on one step starts closed on the next', (
    tester,
  ) async {
    await pumpRunner(tester, steps: [squat, squat]);

    await tester.tap(find.text('Form tip'));
    await tester.pump();
    expect(find.text(squat.notes!), findsOneWidget);

    await tester.tap(control('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(squat.notes!), findsNothing);
  });

  testWidgets('the bar says what is next, then that it is the last step', (
    tester,
  ) async {
    await pumpRunner(tester, steps: [squat, timer('Rest', 60)]);
    expect(find.text('Next · Rest · 01:00'), findsOneWidget);

    await tester.tap(control('Done'));
    await tester.pump();
    expect(find.text('Last step'), findsOneWidget);
  });

  testWidgets('the summary says how it went against last time', (tester) async {
    final earlier = WorkoutSession(
      id: 'earlier',
      planId: 'plan-1',
      planName: 'Test Plan', // what planOf names every plan
      startedAt: DateTime(2020, 1, 6, 18), // a Monday, well before now
      stepsCompleted: 1,
    );
    await pumpRunner(tester, steps: [squat, squat], history: [earlier]);

    await tester.tap(control('Done'));
    await tester.pump();
    await tester.tap(control('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('vs Mon 6:'), findsOneWidget);
    expect(find.textContaining('+1 done'), findsOneWidget);
  });

  testWidgets('with no earlier run, the summary says nothing about it', (
    tester,
  ) async {
    await pumpRunner(tester, steps: [squat]);
    await tester.tap(control('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('vs '), findsNothing);
  });

  testWidgets('the control bar reaches the bottom edge, past the home '
      'indicator, with the controls above it', (tester) async {
    // An iPhone with a home indicator: 34 points of bottom inset.
    await pumpRunner(tester, steps: [squat, squat], bottomInset: 34);

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final bar = tester.getRect(
      find.byKey(const ValueKey('runner-control-bar')),
    );
    expect(bar.bottom, screen.height, reason: 'no strip of page under the bar');

    final done = tester.getRect(find.bySemanticsLabel('Done'));
    expect(done.bottom, lessThanOrEqualTo(screen.height - 34));
  });

  group('exercise demos', () {
    final demoSquat = squat.copyWith(exerciseId: '0001');

    /// Lets the demo lookup resolve, then the frame that shows it.
    Future<void> settleDemo(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> swipeToDemo(WidgetTester tester) async {
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Finder credit() => find.textContaining(AppConfig.exerciseMediaCredit);

    testWidgets('a step without a demo keeps the plain dial', (tester) async {
      await pumpRunner(
        tester,
        steps: [squat],
        demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])),
      );
      await settleDemo(tester);

      expect(find.byType(PageView), findsNothing);
      expect(control('Show exercise demo'), findsNothing);
    });

    testWidgets('a demo that was never downloaded keeps the plain dial', (
      tester,
    ) async {
      await pumpRunner(
        tester,
        steps: [demoSquat],
        demos: oneDemo(FakeExerciseMediaStore()),
      );
      await settleDemo(tester);

      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('swiping the dial shows the demo, the target stays in view', (
      tester,
    ) async {
      await pumpRunner(
        tester,
        steps: [demoSquat],
        demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])),
      );
      await settleDemo(tester);
      expect(credit().hitTestable(), findsNothing);

      await swipeToDemo(tester);

      expect(credit().hitTestable(), findsOneWidget);
      expect(find.text('×10').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no overflow');

      await tester.drag(find.byType(PageView), const Offset(600, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(credit().hitTestable(), findsNothing);
    });

    testWidgets('the dots switch pages without a swipe', (tester) async {
      await pumpRunner(
        tester,
        steps: [demoSquat],
        demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])),
      );
      await settleDemo(tester);

      await tester.tap(control('Show exercise demo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(credit().hitTestable(), findsOneWidget);

      await tester.tap(control('Show timer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(credit().hitTestable(), findsNothing);
    });

    testWidgets('the next step opens on its dial', (tester) async {
      await pumpRunner(
        tester,
        steps: [demoSquat, demoSquat],
        demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])),
      );
      await settleDemo(tester);
      await swipeToDemo(tester);

      await tester.tap(control('Done'));
      await settleDemo(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PageView), findsOneWidget);
      expect(credit().hitTestable(), findsNothing);
    });

    testWidgets('fits a short phone at 2x text', (tester) async {
      await pumpRunner(
        tester,
        steps: [demoSquat],
        size: const Size(750, 1334),
        devicePixelRatio: 2,
        textScale: 2,
        demos: oneDemo(FakeExerciseMediaStore(available: ['0001'])),
      );
      await settleDemo(tester);
      // At 2x text the stage scrolls, and the pager starts under the bar.
      await tester.ensureVisible(find.byType(PageView));
      await tester.pump();
      await swipeToDemo(tester);

      expect(credit().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(control('Done'), findsOneWidget);
    });

    testWidgets('reduced motion shows the still, not the animation', (
      tester,
    ) async {
      final media = FakeExerciseMediaStore(available: ['0001']);
      await pumpRunner(
        tester,
        steps: [demoSquat],
        demos: oneDemo(media),
        reduceMotion: true,
      );
      await settleDemo(tester);

      expect(media.stillRequests, [true]);
    });

    testWidgets('an animated demo is asked for otherwise', (tester) async {
      final media = FakeExerciseMediaStore(available: ['0001']);
      await pumpRunner(tester, steps: [demoSquat], demos: oneDemo(media));
      await settleDemo(tester);

      expect(media.stillRequests, [false]);
    });
  });
}
