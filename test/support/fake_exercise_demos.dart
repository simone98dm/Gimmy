import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/exercises/exercise_media_store.dart';

/// A 1×1 transparent GIF, so a demo can actually be drawn in a widget test.
final transparentGif = Uint8List.fromList(const [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, //
  0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x21, 0xF9, 0x04, 0x01, 0x00, //
  0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, //
  0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
]);

/// Demos held in memory: nothing is downloaded, and every prefetched entry
/// becomes available, unless its id is in [failing]. [available] starts as
/// if already downloaded.
class FakeExerciseMediaStore implements ExerciseMediaStore {
  FakeExerciseMediaStore({
    this.failing = const {},
    Iterable<String> available = const [],
  }) : _available = {...available};

  final Set<String> failing;
  final List<String> prefetched = [];
  final Set<String> _available;

  /// Every [demoFor] call, as whether it asked for the still.
  final List<bool> stillRequests = [];

  @override
  Future<void> prefetch(Iterable<CatalogEntry> entries) async {
    for (final entry in entries) {
      prefetched.add(entry.id);
      if (!failing.contains(entry.id)) _available.add(entry.id);
    }
  }

  @override
  Future<ImageProvider?> demoFor(
    CatalogEntry entry, {
    bool still = false,
  }) async {
    stillRequests.add(still);
    return _available.contains(entry.id) ? MemoryImage(transparentGif) : null;
  }
}

/// Provides [ExerciseDemos] for pages that read it — Import and the
/// Execution page. By default there are no demos at all: the bundled catalog
/// is an asset read, which never completes under a widget test's fake async.
Widget withExerciseDemos(Widget child, {ExerciseDemos? demos}) {
  return RepositoryProvider(
    create: (_) =>
        demos ??
        ExerciseDemos(
          media: FakeExerciseMediaStore(),
          loadCatalog: () async => const ExerciseCatalog([]),
        ),
    child: child,
  );
}

/// Demos switched on, over one catalog exercise, `0001`, whose demo is
/// already downloaded.
ExerciseDemos oneDemo(FakeExerciseMediaStore media) => ExerciseDemos(
  isEnabled: true,
  media: media,
  loadCatalog: () async => const ExerciseCatalog([
    CatalogEntry(
      id: '0001',
      name: 'barbell full squat',
      equipment: 'barbell',
      gif: 'videos/0001.gif',
      image: 'images/0001.jpg',
    ),
  ]),
);
