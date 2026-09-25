import '../models/workout_session.dart';
import 'document_store.dart';
import 'open_document_store.dart';
import '../../core/logging/app_log.dart';

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

  Future<List<WorkoutSession>> loadAll() async => _parse(await _entries());

  /// Inserts [session], or replaces the stored one with the same id.
  ///
  /// The Execution page saves the same session as it goes — at the start,
  /// after each step, at the end — so upsert is the normal path.
  ///
  /// Works on the raw entries, not the parsed ones: an entry this build cannot
  /// read (a newer format, a damaged record) is written back as it was, not
  /// dropped because something else was saved.
  Future<List<WorkoutSession>> upsert(WorkoutSession session) async {
    final updated = [
      for (final entry in await _entries())
        if (!(entry is Map && entry['id'] == session.id)) entry,
      session.toJson(),
    ]..sort((a, b) => _startedAt(a).compareTo(_startedAt(b)));

    await _store.write(updated);
    return _parse(updated);
  }

  /// The stored entries as they are on disk.
  Future<List<Object?>> _entries() async {
    final document = await _store.read();
    if (document == null) return const [];

    // A file that is not even a list is unreadable as a whole: start over.
    if (document is! List) {
      AppLog.error('storage', 'session history unreadable, discarding it');
      await _store.delete();
      return const [];
    }
    return document;
  }

  /// Entry by entry: one bad session must not take the rest of the history
  /// with it. It is logged and left out of what the app sees.
  static List<WorkoutSession> _parse(List<Object?> entries) {
    final sessions = <WorkoutSession>[];
    for (final entry in entries) {
      try {
        sessions.add(WorkoutSession.fromJson(entry! as Map<String, dynamic>));
      } on Object catch (error) {
        AppLog.warning('storage', 'skipping an unreadable session', error);
      }
    }
    return List.unmodifiable(sessions);
  }

  /// ISO-8601 sorts as text; an entry without a readable start sorts first.
  static String _startedAt(Object? entry) =>
      entry is Map && entry['startedAt'] is String
      ? entry['startedAt'] as String
      : '';

  Future<void> clear() => _store.delete();
}
