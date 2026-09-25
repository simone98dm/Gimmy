import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/session_comparison.dart';
import 'package:gimmy/features/history/comparison_text.dart';

import '../../data/session_comparison_test.dart' show run, step;

void main() {
  final then = DateTime(2026, 9, 23, 18); // a Wednesday
  final now = DateTime(2026, 9, 25, 18);

  test('signs changes with a real minus and fitting units', () {
    expect(signedDuration(180), '+3 min');
    expect(signedDuration(-45), '−45 s');
    expect(signedDuration(15, clock: true), '+0:15');
    expect(signedDuration(-65, clock: true), '−1:05');
  });

  test('the summary line names the day and each change', () {
    final c = SessionComparison.of(
      run('now', now, done: 7, seconds: 1380, bpm: 128),
      run('then', then, done: 5, seconds: 1200, bpm: 132),
    );
    expect(
      comparisonLine(c),
      'vs Wed 23: +3 min active · +2 done · −4 avg BPM',
    );
  });

  test('no change reads as the same, and heart rate needs both sides', () {
    final c = SessionComparison.of(
      run('now', now, bpm: 120),
      run('then', then),
    );
    expect(comparisonLine(c), 'vs Wed 23: same time · same steps done');
  });

  test('is read aloud in words', () {
    final c = SessionComparison.of(
      run('now', now, done: 4, seconds: 1380, bpm: 128),
      run('then', then, done: 5, seconds: 1200, bpm: 132),
    );
    expect(
      spokenComparison(c),
      'Compared with Wednesday: 3 minutes more active, 1 fewer step done, '
      '4 BPM lower average',
    );
  });

  test('a step line says what changed, outcome first', () {
    final c = SessionComparison.of(
      run(
        'now',
        now,
        steps: [
          step('Squat', seconds: 75, bpm: 130),
          step('Row', outcome: StepOutcome.skipped),
        ],
      ),
      run(
        'then',
        then,
        steps: [
          step('Squat', seconds: 60, bpm: 134, outcome: StepOutcome.skipped),
          step('Row'),
        ],
      ),
    );
    expect(
      stepChangeLine(c.step(0)!, StepOutcome.done),
      'skipped before · +0:15 · −4 BPM',
    );
    expect(stepChangeLine(c.step(1)!, StepOutcome.skipped), 'done before');
  });
}
