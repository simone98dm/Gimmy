import 'package:flutter/painting.dart';

import '../../core/config/feature_flags.dart';
import 'exercise_catalog.dart';

/// The exercise demos, wherever this platform can keep them.
///
/// Mobile downloads them on import so the workout runs offline; the web has
/// no room for them in local storage and leaves them to the browser cache.
/// Callers depend on this, never on either. See `openExerciseMediaStore`.
abstract class ExerciseMediaStore {
  /// Makes the demos of [entries] available offline, where the platform can.
  ///
  /// Never throws: a demo that fails to download is logged and skipped, and
  /// its step simply shows no demo.
  Future<void> prefetch(Iterable<CatalogEntry> entries);

  /// The animated demo of [entry], or its [still] thumbnail; null when it is
  /// not available.
  Future<ImageProvider?> demoFor(CatalogEntry entry, {bool still = false});
}

/// Where a dataset media path, e.g. `videos/0001-x.gif`, is downloaded from.
Uri exerciseMediaUri(String path) =>
    Uri.parse('${AppConfig.exerciseMediaBaseUrl}/$path');
