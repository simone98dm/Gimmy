/// A single JSON document, wherever this platform can keep one.
///
/// Mobile writes a real file; the web has no filesystem and uses the browser's
/// local storage instead. Repositories depend on this, never on either.
abstract class DocumentStore {
  /// The decoded document, or null when nothing is stored.
  ///
  /// A stored document that cannot be parsed reads as null: the app recovers
  /// into its empty state rather than refusing to start.
  Future<Object?> read();

  Future<void> write(Object? document);

  Future<void> delete();
}
