import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';

import '../../support/fake_exercise_demos.dart';

CatalogEntry _entry(String id, String name) => CatalogEntry(
  id: id,
  name: name,
  equipment: 'body weight',
  gif: 'videos/$id.gif',
  image: 'images/$id.jpg',
);

final _catalog = ExerciseCatalog([
  _entry('0001', 'squat'),
  _entry('0002', 'plank'),
  _entry('0003', 'rest pause'),
]);

Plan _plan() => Plan(
  id: 'p',
  name: 'Legs',
  sourceFilename: 'legs.fit',
  importedAt: DateTime(2026, 9, 25),
  steps: [
    PlanStep.timer(
      name: 'Warm-up',
      intensity: StepIntensity.warmup,
      durationSeconds: 60,
    ),
    PlanStep.reps(name: 'Squat', intensity: StepIntensity.active, repCount: 10),
    PlanStep.timer(
      name: 'Rest',
      intensity: StepIntensity.rest,
      durationSeconds: 30,
    ),
    PlanStep.reps(name: 'Squat', intensity: StepIntensity.active, repCount: 10),
    PlanStep.timer(
      name: 'Jumping jack',
      intensity: StepIntensity.active,
      durationSeconds: 30,
    ),
  ],
);

void main() {
  late FakeExerciseMediaStore media;
  late ExerciseDemos demos;

  setUp(() {
    media = FakeExerciseMediaStore();
    demos = ExerciseDemos(
      media: media,
      loadCatalog: () async => _catalog,
      isEnabled: true,
    );
  });

  group('match', () {
    test('gives every step of a matched exercise the same demo', () async {
      final ids = (await demos.match(_plan())).steps.map((s) => s.exerciseId);

      expect(ids, [null, '0001', null, '0001', null]);
    });

    test('never matches rest, warm-up or cool-down steps', () async {
      final plan = _plan().copyWith(
        steps: [
          PlanStep.timer(
            name: 'Rest pause',
            intensity: StepIntensity.rest,
            durationSeconds: 30,
          ),
        ],
      );

      expect((await demos.match(plan)).steps.single.exerciseId, isNull);
    });

    test(
      'a catalog that fails to load costs the demos, not the import',
      () async {
        final broken = ExerciseDemos(
          isEnabled: true,
          media: media,
          loadCatalog: () async => throw const FormatException('bad asset'),
        );

        expect(await broken.match(_plan()), _plan());
      },
    );
  });

  group('prefetch', () {
    test('fetches each chosen demo once', () async {
      final plan = await demos.match(_plan());

      await demos.prefetch(plan);

      expect(media.prefetched, ['0001']);
    });

    test('skips an id the catalog no longer has', () async {
      final plan = _plan().withExercise('Squat', '9999');

      await demos.prefetch(plan);

      expect(media.prefetched, isEmpty);
    });
  });

  group('demoFor', () {
    test('serves a prefetched demo', () async {
      await demos.prefetch(await demos.match(_plan()));

      expect(await demos.demoFor('0001'), isNotNull);
    });

    test('has nothing for an unknown or missing demo', () async {
      expect(await demos.demoFor('0002'), isNull);
      expect(await demos.demoFor('9999'), isNull);
    });
  });

  test('the catalog is loaded once', () async {
    var loads = 0;
    final counted = ExerciseDemos(
      isEnabled: true,
      media: media,
      loadCatalog: () async {
        loads++;
        return _catalog;
      },
    );

    await counted.match(_plan());
    await counted.demoFor('0001');

    expect(loads, 1);
  });

  group('Plan.withExercise', () {
    test('sets the demo of every step with that name', () {
      final ids = _plan()
          .withExercise('Squat', '0001')
          .steps
          .map((s) => s.exerciseId);

      expect(ids, [null, '0001', null, '0001', null]);
    });

    test('null clears it', () {
      final plan = _plan()
          .withExercise('Squat', '0001')
          .withExercise('Squat', null);

      expect(plan.steps.every((s) => s.exerciseId == null), isTrue);
    });
  });

  group('switched off', () {
    late ExerciseDemos off;

    setUp(() {
      off = ExerciseDemos(
        media: FakeExerciseMediaStore(available: ['0001']),
        loadCatalog: () async => _catalog,
        isEnabled: false,
      );
    });

    test('is the default, as FeatureFlags.showExerciseDemos says', () {
      expect(ExerciseDemos(media: media).isEnabled, isFalse);
    });

    test('matches nothing', () async {
      expect(await off.match(_plan()), _plan());
    });

    test('downloads nothing', () async {
      final quiet = FakeExerciseMediaStore();
      final demos = ExerciseDemos(
        media: quiet,
        loadCatalog: () async => _catalog,
        isEnabled: false,
      );

      await demos.prefetch(_plan().withExercise('Squat', '0001'));

      expect(quiet.prefetched, isEmpty);
    });

    test('shows nothing, even for a plan saved with demos', () async {
      expect(await off.demoFor('0001'), isNull);
    });
  });
}
