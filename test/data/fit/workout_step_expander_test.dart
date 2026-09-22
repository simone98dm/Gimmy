import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/fit/fit_parse_exception.dart';
import 'package:gimmy/data/fit/workout_step_expander.dart';
import 'package:gimmy/data/models/plan_step.dart';

RawStep exercise(int index, String name) => RawStep.exercise(
  messageIndex: index,
  step: PlanStep.reps(
    name: name,
    intensity: StepIntensity.active,
    repCount: 10,
  ),
);

RawStep repeat(int index, {required int from, required int count}) =>
    RawStep.repeat(
      messageIndex: index,
      repeatFromIndex: from,
      repeatCount: count,
    );

List<String> namesOf(List<PlanStep> steps) => steps.map((s) => s.name).toList();

void main() {
  group('expandRepeats', () {
    test('passes a plan with no repeats through unchanged', () {
      final raw = [exercise(0, 'A'), exercise(1, 'B')];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['A', 'B']);
    });

    test('runs a block count times in total, not count times extra', () {
      // The marker follows a block that has already executed once.
      final raw = [
        exercise(0, 'A'),
        exercise(1, 'B'),
        repeat(2, from: 0, count: 3),
      ];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['A', 'B', 'A', 'B', 'A', 'B']);
    });

    test('a count of 1 leaves the block as a single pass', () {
      final raw = [exercise(0, 'A'), repeat(1, from: 0, count: 1)];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['A']);
    });

    test('keeps steps that sit outside the repeated block', () {
      final raw = [
        exercise(0, 'warmup'),
        exercise(1, 'A'),
        repeat(2, from: 1, count: 2),
        exercise(3, 'cooldown'),
      ];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['warmup', 'A', 'A', 'cooldown']);
    });

    test('runs back-to-back blocks independently', () {
      final raw = [
        exercise(0, 'A'),
        repeat(1, from: 0, count: 2),
        exercise(2, 'B'),
        repeat(3, from: 2, count: 3),
      ];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['A', 'A', 'B', 'B', 'B']);
    });

    test('nests: the inner block restarts on every outer iteration', () {
      final raw = [
        exercise(0, 'A'),
        repeat(1, from: 0, count: 2), // inner: A A
        exercise(2, 'B'),
        repeat(3, from: 0, count: 2), // outer: (A A B) twice
      ];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['A', 'A', 'B', 'A', 'A', 'B']);
    });

    test('resolves jumps by message index, not list position', () {
      // Garmin files need not start at zero or stay contiguous.
      final raw = [
        RawStep.exercise(
          messageIndex: 40,
          step: PlanStep.reps(
            name: 'A',
            intensity: StepIntensity.active,
            repCount: 10,
          ),
        ),
        repeat(41, from: 40, count: 2),
      ];

      final steps = expandRepeats(raw);

      expect(namesOf(steps), ['A', 'A']);
    });

    test('rejects a repeat that jumps forward', () {
      final raw = [exercise(0, 'A'), repeat(1, from: 5, count: 2)];

      expect(
        () => expandRepeats(raw),
        throwsA(
          isA<FitParseException>().having(
            (e) => e.failure,
            'failure',
            FitParseFailure.corrupt,
          ),
        ),
      );
    });

    test('rejects a repeat that jumps to itself', () {
      final raw = [exercise(0, 'A'), repeat(1, from: 1, count: 2)];

      expect(
        () => expandRepeats(raw),
        throwsA(
          isA<FitParseException>().having(
            (e) => e.failure,
            'failure',
            FitParseFailure.corrupt,
          ),
        ),
      );
    });

    test('refuses to expand a plan beyond the step ceiling', () {
      final raw = [exercise(0, 'A'), repeat(1, from: 0, count: 100000)];

      expect(
        () => expandRepeats(raw),
        throwsA(
          isA<FitParseException>().having(
            (e) => e.failure,
            'failure',
            FitParseFailure.tooManySteps,
          ),
        ),
      );
    });
  });
}
