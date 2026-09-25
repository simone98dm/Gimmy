import 'package:flutter/painting.dart';

import 'exercise_catalog.dart';
import 'exercise_media_store.dart';

/// Opens the demo source for the browser.
ExerciseMediaStore openExerciseMediaStore() => NetworkExerciseMediaStore();

/// Demos straight from the pinned dataset URL.
///
/// Local storage holds ~5 MB, too little for demos, so nothing is prefetched
/// and the browser's HTTP cache keeps what was shown. The host allows
/// cross-origin reads, which the web renderer needs to draw the image.
class NetworkExerciseMediaStore implements ExerciseMediaStore {
  @override
  Future<void> prefetch(Iterable<CatalogEntry> entries) async {}

  @override
  Future<ImageProvider?> demoFor(
    CatalogEntry entry, {
    bool still = false,
  }) async => NetworkImage(
    exerciseMediaUri(still ? entry.image : entry.gif).toString(),
  );
}
