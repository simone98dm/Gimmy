import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';
import 'package:gimmy/data/exercises/exercise_matcher.dart';

CatalogEntry _entry(
  String id,
  String name, {
  String equipment = 'body weight',
}) => CatalogEntry(
  id: id,
  name: name,
  equipment: equipment,
  gif: 'videos/$id.gif',
  image: 'images/$id.jpg',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('against the bundled catalog', () {
    late ExerciseCatalog catalog;

    setUpAll(() async => catalog = await ExerciseCatalog.load(rootBundle));

    // The contract: what a real FIT step name resolves to. Change the ranking
    // and this table says what moved.
    const expected = <String, String?>{
      'Push-up': 'push-up',
      'Push up': 'push-up',
      'Pushups': 'push-up',
      'Burpees': 'burpee',
      'Mountain climbers': 'mountain climber',
      'Squat': 'dumbbell squat',
      'Squat 2': 'dumbbell squat',
      'Row left': 'inverted row',
      'Plank': 'weighted front plank',
      'Leg extension': 'lever leg extension',
      'Leg Extensions': 'lever leg extension',
      'Biceps curl': 'dumbbell biceps curl',
      'Lunges': 'dumbbell lunge',
      'Bench press': 'dumbbell bench press',
      'Lateral raise': 'dumbbell lateral raise',
      'Jumping jack': null,
      'Rest': null,
      '': null,
    };

    for (final MapEntry(key: stepName, value: name) in expected.entries) {
      test('"$stepName" → ${name ?? 'no demo'}', () {
        expect(matchExercise(stepName, catalog)?.name, name);
      });
    }
  });

  group('ranking', () {
    test('an exact name wins over a shorter contained one', () {
      final catalog = ExerciseCatalog([
        _entry('1', 'jump squat'),
        _entry('2', 'squat'),
      ]);
      expect(matchExercise('Squat', catalog)?.id, '2');
    });

    test('an extra equipment word costs less than a movement word', () {
      final catalog = ExerciseCatalog([
        _entry('1', 'jump squat'),
        _entry('2', 'barbell squat', equipment: 'barbell'),
      ]);
      expect(matchExercise('Squat', catalog)?.id, '2');
    });

    test('dumbbell is preferred over barbell and other equipment', () {
      final catalog = ExerciseCatalog([
        _entry('1', 'barbell lunge', equipment: 'barbell'),
        _entry('2', 'dumbbell lunge', equipment: 'dumbbell'),
        _entry('3', 'weighted lunge', equipment: 'weighted'),
      ]);
      expect(matchExercise('Lunge', catalog)?.id, '2');
    });

    test('every word of the step name must appear', () {
      final catalog = ExerciseCatalog([_entry('1', 'leg press')]);
      expect(matchExercise('Leg extension', catalog), isNull);
    });

    test('side and set markers are ignored', () {
      final catalog = ExerciseCatalog([_entry('1', 'lunge')]);
      for (final name in [
        'Lunge left',
        'Lunge RIGHT',
        'Lunge sx',
        'Lunge 3',
        'Lunge x2',
      ]) {
        expect(matchExercise(name, catalog)?.id, '1', reason: name);
      }
    });
  });
}
