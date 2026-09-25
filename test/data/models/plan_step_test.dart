import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/plan_step.dart';

void main() {
  final squat = PlanStep.reps(
    name: 'Squat',
    intensity: StepIntensity.active,
    repCount: 10,
  );

  group('exerciseId', () {
    test('is null on a step fresh from the FIT parser', () {
      expect(squat.exerciseId, isNull);
    });

    test('survives a round trip through JSON', () {
      final matched = squat.copyWith(exerciseId: '0662');

      expect(PlanStep.fromJson(matched.toJson()), matched);
      expect(PlanStep.fromJson(matched.toJson()).exerciseId, '0662');
    });

    test('is left out of the JSON when there is none', () {
      expect(squat.toJson().containsKey('exerciseId'), isFalse);
    });

    test('loads steps saved before demos existed', () {
      // The exact shape PlanStep.toJson wrote before exerciseId.
      final old = {
        'name': 'Plank',
        'type': 'timer',
        'intensity': 'active',
        'durationSeconds': 30,
      };

      final step = PlanStep.fromJson(old);
      expect(step.exerciseId, isNull);
      expect(step.durationSeconds, 30);
    });

    test('tells steps with different demos apart', () {
      expect(
        squat.copyWith(exerciseId: '0001'),
        isNot(squat.copyWith(exerciseId: '0002')),
      );
    });

    test('can be cleared, for "no demo" on import', () {
      final matched = squat.copyWith(exerciseId: '0662');

      expect(matched.copyWith(clearExerciseId: true).exerciseId, isNull);
      expect(matched.copyWith(name: 'Deep squat').exerciseId, '0662');
    });
  });
}
