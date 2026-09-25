import 'exercise_catalog.dart';

/// Picks the catalog exercise a FIT step name most likely means, or null.
///
/// Step names are short ("Squat", "Row left"); catalog names are specific
/// ("dumbbell squat", "inverted row"). So after an exact match, a candidate
/// must contain every word of the step name, and among those the one that
/// adds the fewest words that change the movement wins. A wrong pick is
/// corrected on import; a miss just means no demo.
CatalogEntry? matchExercise(String stepName, ExerciseCatalog catalog) {
  final query = _tokens(stepName).where(_isMeaningful).toList();
  if (query.isEmpty) return null;

  final joined = query.join();
  for (final entry in catalog.entries) {
    if (_tokens(entry.name).join() == joined) return entry;
  }

  CatalogEntry? best;
  List<int>? bestRank;
  for (final entry in catalog.entries) {
    final rank = _rank(query, entry);
    if (rank == null) continue;
    if (bestRank == null || _compare(rank, bestRank) < 0) {
      best = entry;
      bestRank = rank;
    }
  }
  return best;
}

/// Lower is better: movement-changing extra words, equipment preference,
/// extra words overall. Null when a word of the query is missing. Ties keep
/// the first entry, and the catalog is sorted by id.
List<int>? _rank(List<String> query, CatalogEntry entry) {
  final words = _tokens(entry.name);
  if (!query.every(words.contains)) return null;

  final extra = words.where((w) => !query.contains(w)).toList();
  final costly = extra.where(
    (w) => !_freeWords.contains(w) && !_digits.hasMatch(w),
  );
  final equipment = _equipmentPreference.indexOf(entry.equipment);

  return [
    costly.length,
    equipment == -1 ? _equipmentPreference.length : equipment,
    extra.length,
  ];
}

int _compare(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

/// Lowercase words with hyphens joined ("push-up" = "push up" = "pushup"
/// only through the exact match) and a plural "s" dropped.
List<String> _tokens(String name) => name
    .toLowerCase()
    .replaceAll('-', '')
    .split(_separators)
    .where((w) => w.isNotEmpty)
    .map(_singular)
    .toList();

// ponytail: strips a trailing "s", good enough for exercise names; not a stemmer.
String _singular(String word) =>
    word.length > 3 && word.endsWith('s') && !word.endsWith('ss')
    ? word.substring(0, word.length - 1)
    : word;

/// Drops what says which side or which set, not which exercise.
bool _isMeaningful(String word) =>
    !_sideWords.contains(word) && !_setMarker.hasMatch(word);

final _separators = RegExp('[^a-z0-9]+');
final _digits = RegExp(r'^\d+$');
final _setMarker = RegExp(r'^x?\d+$');

const _sideWords = {'left', 'right', 'sx', 'dx'};

/// Words in a catalog name that name the equipment or the variant's
/// illustration, not a different movement.
const _freeWords = {
  'barbell',
  'dumbbell',
  'cable',
  'lever',
  'band',
  'smith',
  'kettlebell',
  'weighted',
  'resistance',
  'ez',
  'trap',
  'bar',
  'machine',
  'bodyweight',
  'male',
  'female',
  'v',
};

const _equipmentPreference = ['body weight', 'dumbbell', 'barbell'];
