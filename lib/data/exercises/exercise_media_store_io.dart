import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/feature_flags.dart';
import '../../core/logging/app_log.dart';
import 'exercise_catalog.dart';
import 'exercise_media_store.dart';

/// Opens the demo cache in the app's documents directory.
ExerciseMediaStore openExerciseMediaStore() => FileExerciseMediaStore();

/// Downloads the bytes at a URL. Injected by tests.
typedef MediaFetch = Future<List<int>> Function(Uri uri);

/// Demos as files under `<documents>/exercise_media/`, at the same relative
/// path they have in the dataset.
///
/// A download is written to a temporary file and then renamed, so a demo on
/// disk is always a whole one. Nothing is evicted: a plan's demos are a
/// megabyte or two.
class FileExerciseMediaStore implements ExerciseMediaStore {
  FileExerciseMediaStore({Directory? directory, MediaFetch? fetch})
    : _directory = directory,
      _fetch = fetch ?? _httpFetch;

  final Directory? _directory;
  final MediaFetch _fetch;

  Future<File> _file(String path) async {
    final dir = _directory ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/exercise_media/$path');
  }

  @override
  Future<void> prefetch(Iterable<CatalogEntry> entries) async {
    final paths = [
      for (final e in entries) ...[e.gif, e.image],
    ];
    // ponytail: one at a time, a plan has a handful of exercises.
    for (final path in paths) {
      await _download(path);
    }
  }

  Future<void> _download(String path) async {
    final file = await _file(path);
    if (file.existsSync()) return;

    final temp = File('${file.path}.tmp');
    try {
      final bytes = await _fetch(exerciseMediaUri(path));
      if (bytes.isEmpty) throw const HttpException('empty response');

      await file.parent.create(recursive: true);
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
      AppLog.info('media', 'downloaded $path');
    } on Exception catch (error) {
      AppLog.warning('media', 'could not download $path', error);
      if (temp.existsSync()) await temp.delete();
    }
  }

  @override
  Future<ImageProvider?> demoFor(
    CatalogEntry entry, {
    bool still = false,
  }) async {
    final file = await _file(still ? entry.image : entry.gif);
    return file.existsSync() ? FileImage(file) : null;
  }
}

Future<List<int>> _httpFetch(Uri uri) async {
  final client = HttpClient()
    ..connectionTimeout = AppConfig.exerciseMediaTimeout;
  try {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(
      AppConfig.exerciseMediaTimeout,
    );
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    final chunks = await response.toList().timeout(
      AppConfig.exerciseMediaTimeout,
    );
    return [for (final chunk in chunks) ...chunk];
  } finally {
    client.close();
  }
}
