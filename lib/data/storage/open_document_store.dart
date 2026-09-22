/// Picks the storage backend for this platform.
///
/// `dart.library.js_interop` is only defined when compiling for the web, so a
/// mobile build never sees the browser implementation and a web build never
/// sees `dart:io`.
library;

export 'document_store_io.dart'
    if (dart.library.js_interop) 'document_store_web.dart';
