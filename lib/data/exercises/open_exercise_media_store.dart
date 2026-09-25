/// Picks the demo store for this platform; see `open_document_store.dart`.
library;

export 'exercise_media_store_io.dart'
    if (dart.library.js_interop) 'exercise_media_store_web.dart';
