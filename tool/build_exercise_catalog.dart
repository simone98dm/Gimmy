// Trims the exercises dataset into the catalog the app bundles.
//
//   git clone https://github.com/hasaneyldrm/exercises-dataset /tmp/ds
//   git -C /tmp/ds checkout 7455efae41b330c265e7cd4b78dfa848e7ce5ebd
//   dart run tool/build_exercise_catalog.dart /tmp/ds
//
// The dataset's JSON is MIT. Its media (the gif/image paths below) is
// © Gym visual and is not copied here; the app downloads it on import.
import 'dart:convert';
import 'dart:io';

const _output = 'assets/exercises/catalog.json';
const _license = 'assets/exercises/LICENSE';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/build_exercise_catalog.dart <dataset>',
    );
    exit(64);
  }

  final source = File('${args.single}/data/exercises.json');
  final records = jsonDecode(source.readAsStringSync()) as List;

  final entries = [
    for (final r in records.cast<Map<String, dynamic>>())
      {
        'id': r['id'],
        'name': r['name'],
        'equipment': r['equipment'],
        'gif': r['gif_url'],
        'image': r['image'],
      },
  ]..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  // One entry per line, so a dataset bump reads as a diff.
  final lines = entries.map(jsonEncode).join(',\n');
  File(_output).writeAsStringSync('[\n$lines\n]\n');
  stdout.writeln('Wrote ${entries.length} exercises to $_output');

  // The catalog is a copy of MIT data: its notice ships with it, and is
  // listed on the About page's licences (registerExerciseDatasetLicense).
  File('${args.single}/LICENSE').copySync(_license);
  stdout.writeln('Copied the dataset licence to $_license');
}
