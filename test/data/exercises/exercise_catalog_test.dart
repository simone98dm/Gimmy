import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled catalog holds every exercise of the dataset', () async {
    final catalog = await ExerciseCatalog.load(rootBundle);

    expect(catalog.entries, hasLength(1324));
    expect(catalog.entries.map((e) => e.id).toSet(), hasLength(1324));
  });

  test('an entry carries what matching and the media cache need', () async {
    final catalog = await ExerciseCatalog.load(rootBundle);

    final pushUp = catalog.byId('0662');
    expect(pushUp?.name, 'push-up');
    expect(pushUp?.equipment, 'body weight');
    expect(pushUp?.gif, 'videos/0662-I4hDWkc.gif');
    expect(pushUp?.image, 'images/0662-I4hDWkc.jpg');
  });

  test('an unknown id reads as null', () {
    const catalog = ExerciseCatalog([]);
    expect(catalog.byId('9999'), isNull);
  });

  test('a malformed entry is rejected', () {
    expect(
      () => ExerciseCatalog.parse('[{"id": "0001"}]'),
      throwsFormatException,
    );
  });

  test('the dataset licence is listed with the app\'s licences', () async {
    registerExerciseDatasetLicense();

    final entries = await LicenseRegistry.licenses.toList();
    final dataset = entries.where(
      (e) => e.packages.contains('exercises-dataset'),
    );
    expect(dataset, hasLength(1));
    final text = dataset.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Hasan Emir Y'));
    expect(text, contains('Gym visual'));
  });
}
