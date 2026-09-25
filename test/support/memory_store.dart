import 'package:flutter/foundation.dart';
import 'package:gimmy/data/storage/document_store.dart';

/// A [DocumentStore] that completes synchronously.
///
/// For tests about logic rather than the disk: real file I/O makes any wait
/// measured in event-loop turns a race, and never completes at all under a
/// widget test's fake async. Durability is covered in `repositories_test`.
class MemoryStore implements DocumentStore {
  /// [isWriteSlow] makes every write take an event-loop turn, like a disk,
  /// for tests about what happens while a save is still in flight.
  MemoryStore({this.isWriteSlow = false});

  final bool isWriteSlow;
  Object? _document;

  /// How many times [write] was called, so a test can tell one save from two.
  int writes = 0;

  @override
  Future<Object?> read() => SynchronousFuture(_document);

  @override
  Future<void> write(Object? document) {
    writes++;
    _document = document;
    return isWriteSlow
        ? Future<void>.delayed(Duration.zero)
        : SynchronousFuture(null);
  }

  @override
  Future<void> delete() {
    _document = null;
    return SynchronousFuture(null);
  }
}
