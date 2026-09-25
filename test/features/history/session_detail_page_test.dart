import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/features/dashboard/widgets/day_sessions_sheet.dart';
import 'package:gimmy/features/history/view/session_detail_page.dart';

import '../../support/test_fonts.dart';

StepRecord record(
  String name, {
  StepOutcome outcome = StepOutcome.done,
  int seconds = 60,
  int? bpm,
}) => StepRecord(
  name: name,
  target: '10 reps',
  intensity: StepIntensity.active,
  outcome: outcome,
  activeSeconds: seconds,
  averageBpm: bpm,
);

final recorded = WorkoutSession(
  id: 's1',
  planId: 'plan-1',
  planName: 'Full Body Sample',
  startedAt: DateTime(2026, 9, 22, 18),
  endedAt: DateTime(2026, 9, 22, 18, 40),
  totalActiveSeconds: 2280,
  status: SessionStatus.abandoned,
  stepsCompleted: 2,
  stepsSkipped: 1,
  plannedSteps: 7,
  steps: [
    record('Squat', seconds: 72, bpm: 128),
    record('Rest', outcome: StepOutcome.skipped, seconds: 0),
    record('Push-up', seconds: 65, bpm: 141),
  ],
  averageBpm: 132,
  maxBpm: 171,
);

final legacy = WorkoutSession(
  id: 's0',
  planId: 'plan-1',
  planName: 'Full Body Sample',
  startedAt: DateTime(2026, 9, 20, 18),
  totalActiveSeconds: 2100,
  status: SessionStatus.completed,
  stepsCompleted: 20,
  stepsSkipped: 2,
);

/// The totals line keeps each figure on one line with non-breaking spaces.
String figures(String line) =>
    line.split(' · ').map((f) => f.replaceAll(' ', '\u00A0')).join(' · ');

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpPage(
    WidgetTester tester,
    WorkoutSession session, {
    List<WorkoutSession> history = const [],
  }) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: SessionDetailPage(session: session, history: history),
      ),
    );
  }

  testWidgets('replays a recorded session step by step', (tester) async {
    await pumpPage(tester, recorded);

    expect(find.text('ENDED EARLY'), findsOneWidget);
    expect(
      find.text(
        figures(
          '38 min active · 2 of 7 done · 1 skipped · 132 avg / 171 max BPM',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('10 reps · skipped'), findsOneWidget);
    expect(find.text('141'), findsOneWidget);
    expect(find.text('4 steps not reached'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Step 1, Squat, 10 reps, done, 1 min 12 s active, average 128 BPM',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a recorded session, as it looks', tags: ['golden'], (
    tester,
  ) async {
    await pumpPage(tester, recorded);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/session_detail_dark.png'),
    );
  });

  testWidgets('a session from before step records says so', (tester) async {
    await pumpPage(tester, legacy);

    expect(find.text('COMPLETED'), findsOneWidget);
    expect(
      find.text(figures('35 min active · 20 done · 2 skipped')),
      findsOneWidget,
    );
    expect(
      find.text("Step detail isn't available for sessions before this update."),
      findsOneWidget,
    );
    expect(find.textContaining('BPM'), findsNothing);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('a day sheet row opens its session', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDaySessionsSheet(
              context,
              day: recorded.localDay,
              sessions: [recorded],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('open session')));
    await tester.pumpAndSettle();

    expect(find.text('4 steps not reached'), findsOneWidget);
  });

  testWidgets('compares with the last run and opens it', (tester) async {
    final earlier = WorkoutSession(
      id: 's-earlier',
      planId: 'plan-0',
      planName: 'Full Body Sample',
      startedAt: DateTime(2026, 9, 18, 7, 30),
      totalActiveSeconds: 2100,
      status: SessionStatus.completed,
      stepsCompleted: 1,
      plannedSteps: 7,
      steps: [record('Squat', seconds: 57, bpm: 132)],
      averageBpm: 140,
      maxBpm: 165,
    );
    await pumpPage(tester, recorded, history: [earlier, recorded]);

    expect(
      find.text('vs Fri 18: +3 min active · +1 done · −8 avg BPM'),
      findsOneWidget,
    );
    // Squat: 72 s now, 57 s then; 128 BPM now, 132 then.
    expect(find.text('+0:15 · −4 BPM'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Compared with Friday')));
    await tester.pumpAndSettle();
    expect(find.textContaining('September 18, 2026'), findsOneWidget);
  });
}
