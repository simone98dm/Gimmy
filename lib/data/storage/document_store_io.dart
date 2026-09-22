import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'document_store.dart';

/// Opens [name] as a file in the app's documents directory.
DocumentStore openDocumentStore(String name) => FileDocumentStore(name);

/// A single JSON document on disk, in the app's documents directory.
///
/// Writes go to a temporary file and are then renamed over the target, so a
/// crash or a kill mid-write leaves the previous version intact instead of a
/// half-written file. Losing a workout history to a badly timed app switch is
/// not an acceptable failure mode.
class FileDocumentStore implements DocumentStore {
  FileDocumentStore(this.filename, {Directory? directory})
    : _directory = directory;

  /// e.g. `plan.json`.
  final String filename;

  /// Injected by tests. Production resolves the documents directory lazily.
  final Directory? _directory;

  Future<File> _file() async {
    final dir = _directory ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  /// Returns the decoded document, or null when there is nothing stored.
  ///
  /// A file that exists but cannot be parsed is treated as absent: the app
  /// recovers into its empty state rather than refusing to start. The failure
  /// is reported, not swallowed.
  @override
  Future<Object?> read() async {
    final file = await _file();
    if (!file.existsSync()) return null;

    try {
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return null;
      return jsonDecode(contents);
    } on FormatException catch (error) {
      debugPrint('gimmy: $filename holds invalid JSON, ignoring it: $error');
      return null;
    } on FileSystemException catch (error) {
      debugPrint('gimmy: could not read $filename: $error');
      return null;
    }
  }

  @override
  Future<void> write(Object? document) async {
    final file = await _file();
    await file.parent.create(recursive: true);

    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(document), flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> delete() async {
    final file = await _file();
    if (file.existsSync()) await file.delete();

    // A crash between write and rename can leave this behind.
    final temp = File('${file.path}.tmp');
    if (temp.existsSync()) await temp.delete();
  }
}
