import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_log.dart';
import '../models/plan.dart';
import '../models/plan_step.dart';
import 'exercise_catalog.dart';
import 'exercise_matcher.dart';
import 'exercise_media_store.dart';
import 'open_exercise_media_store.dart';

/// Everything the app does with exercise demos: match a plan's exercises to
/// the catalog on import, fetch their media, and hand the runner an image.
///
/// Demos are an extra. Nothing here throws: a catalog that will not load or
/// a demo that will not download leaves the step with its dial only.
class ExerciseDemos {
  ExerciseDemos({
    Future<ExerciseCatalog> Function()? loadCatalog,
    ExerciseMediaStore? media,
  }) : _loadCatalog = loadCatalog ?? (() => ExerciseCatalog.load(rootBundle)),
       _media = media ?? openExerciseMediaStore();

  final Future<ExerciseCatalog> Function() _loadCatalog;
  final ExerciseMediaStore _media;
  Future<ExerciseCatalog>? _catalog;

  /// The catalog, loaded once. Empty when the asset cannot be read.
  Future<ExerciseCatalog> catalog() => _catalog ??= _safeLoad();

  Future<ExerciseCatalog> _safeLoad() async {
    try {
      return await _loadCatalog();
    } on Object catch (error, stackTrace) {
      AppLog.error('demos', 'could not load the catalog', error, stackTrace);
      return const ExerciseCatalog([]);
    }
  }

  /// [plan] with the best catalog match on every working step. Rest,
  /// warm-up and cool-down steps never get a demo.
  Future<Plan> match(Plan plan) async {
    final catalog = await this.catalog();
    var matched = plan;
    for (final name in plan.exerciseNames) {
      final entry = matchExercise(name, catalog);
      if (entry != null) matched = matched.withExercise(name, entry.id);
    }
    AppLog.info(
      'demos',
      'matched ${matched.exerciseIds.length} of '
          '${plan.exerciseNames.length} exercises',
    );
    return matched;
  }

  /// Fetches the media of every demo [plan] uses, where the platform keeps
  /// it offline.
  Future<void> prefetch(Plan plan) async {
    final catalog = await this.catalog();
    final entries = [for (final id in plan.exerciseIds) ?catalog.byId(id)];
    try {
      await _media.prefetch(entries);
    } on Object catch (error, stackTrace) {
      AppLog.error('demos', 'prefetch failed', error, stackTrace);
    }
  }

  /// The demo for [exerciseId], or null when there is none to show.
  Future<ImageProvider?> demoFor(
    String exerciseId, {
    bool still = false,
  }) async {
    final entry = (await catalog()).byId(exerciseId);
    if (entry == null) return null;
    try {
      return await _media.demoFor(entry, still: still);
    } on Object catch (error, stackTrace) {
      AppLog.error(
        'demos',
        'could not open demo $exerciseId',
        error,
        stackTrace,
      );
      return null;
    }
  }
}

extension on Plan {
  /// The distinct demos this plan's steps point at.
  Set<String> get exerciseIds => {
    for (final step in steps)
      if (step.intensity == StepIntensity.active) ?step.exerciseId,
  };
}
