import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/session_comparison.dart';

WorkoutSession run(
  String id,
  DateTime startedAt, {
  String plan = 'Full Body',
  int done = 5,
  int seconds = 1200,
  int? bpm,
  List<StepRecord>? steps,
}) => WorkoutSession(
  id: id,
  planId: 'plan-$id',
  planName: plan,
  startedAt: startedAt,
  totalActiveSeconds: seconds,
  stepsCompleted: done,
  averageBpm: bpm,
  plannedSteps: steps?.length,
  steps: steps ?? const [],
);

StepRecord step(
  String name, {
  int seconds = 60,
  int? bpm,
  StepOutcome outcome = StepOutcome.done,
}) => StepRecord(
  name: name,
  target: '10 reps',
  intensity: StepIntensity.active,
  outcome: outcome,
  activeSeconds: seconds,
  averageBpm: bpm,
);

void main() {
  final today = DateTime(2026, 9, 25, 18);

  group('previousRun', () {
    test('is the latest earlier run of the same plan name', () {
      final current = run('now', today);
      final history = [
        run('old', DateTime(2026, 9, 20)),
        run('recent', DateTime(2026, 9, 23)),
        run('other plan', DateTime(2026, 9, 24), plan: 'Legs'),
        run('later', DateTime(2026, 9, 26)),
        current,
      ];

      expect(previousRun(history, current)?.id, 'recent');
    });

    test('ignores a run where nothing was done', () {
      final current = run('now', today);
      final history = [
        run('real', DateTime(2026, 9, 20)),
        run('opened and left', DateTime(2026, 9, 23), done: 0),
      ];

      expect(previousRun(history, current)?.id, 'real');
    });

    test('is null with no earlier run', () {
      final current = run('now', today);
      expect(previousRun([current], current), isNull);
    });
  });

  group('SessionComparison', () {
    test('reports the changes in totals', () {
      final c = SessionComparison.of(
        run('now', today, done: 7, seconds: 1380, bpm: 128),
        run('then', DateTime(2026, 9, 23), done: 5, seconds: 1200, bpm: 132),
      );

      expect(c.activeSecondsChange, 180);
      expect(c.doneChange, 2);
      expect(c.averageBpmChange, -4);
    });

    test('leaves heart rate out unless both sessions have it', () {
      final c = SessionComparison.of(
        run('now', today, bpm: 128),
        run('then', DateTime(2026, 9, 23)),
      );
      expect(c.averageBpmChange, isNull);
    });

    test('compares a step only when the same step is in the same place', () {
      final c = SessionComparison.of(
        run(
          'now',
          today,
          steps: [
            step('Squat', seconds: 75, bpm: 130),
            step('Plank', seconds: 45),
            step('Row', outcome: StepOutcome.skipped),
          ],
        ),
        run(
          'then',
          DateTime(2026, 9, 23),
          steps: [
            step('Squat', seconds: 60, bpm: 134),
            step('Lunge', seconds: 50),
            step('Row'),
          ],
        ),
      );

      final squat = c.step(0)!;
      expect(squat.secondsChange, 15);
      expect(squat.averageBpmChange, -4);
      expect(c.step(1), isNull, reason: 'Plank was Lunge last time');
      expect(c.step(2)!.previousOutcome, StepOutcome.done);
      expect(c.step(3), isNull, reason: 'no such step');
    });

    test('an older session without step records compares totals only', () {
      final c = SessionComparison.of(
        run('now', today, steps: [step('Squat')]),
        run('then', DateTime(2026, 9, 23)),
      );
      expect(c.doneChange, 0);
      expect(c.step(0), isNull);
    });
  });
}
