import 'package:flutter/foundation.dart';

import '../models/workout_session.dart';
import 'document_store.dart';
import 'open_document_store.dart';

/// Stores every workout session, newest last.
///
/// The whole history is held in one document and filtered in memory. A year of
/// daily workouts is a few hundred small records; a database would buy nothing
/// here. Swap in `drift` if the calendar ever needs real queries.
///
/// Where that document lives is [DocumentStore]'s problem, not this class's.
class SessionRepository {
  SessionRepository({DocumentStore? store})
    : _store = store ?? openDocumentStore('sessions.json');

  final DocumentStore _store;

  Future<List<WorkoutSession>> loadAll() async {
    final document = await _store.read();
    if (document == null) return const [];

    try {
      return List.unmodifiable(
        (document as List).map(
          (entry) => WorkoutSession.fromJson(entry as Map<String, dynamic>),
        ),
      );
    } on Object catch (error) {
      debugPrint(
        'gimmy: session history could not be read, discarding it: $error',
      );
      await _store.delete();
      return const [];
    }
  }

  /// Inserts [session], or replaces the stored one with the same id.
  ///
  /// The Execution page saves the same session twice — once when it starts and
  /// once when it ends — so upsert is the normal path, not an edge case.
  Future<List<WorkoutSession>> upsert(WorkoutSession session) async {
    final existing = await loadAll();
    final updated = [
      for (final s in existing)
        if (s.id != session.id) s,
      session,
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    await _store.write(updated.map((s) => s.toJson()).toList());
    return List.unmodifiable(updated);
  }

  Future<void> clear() => _store.delete();
}
