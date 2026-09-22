# 9. Platform-split storage behind one interface

Date: 2026-09-22

## Status

Accepted. Extends [ADR-0002](0002-json-documents-over-a-database.md).

## Context

Adding web support broke storage. `path_provider` — which resolves the documents directory the
JSON files are written to — has no web implementation. Browsers have no filesystem.

`shared_preferences` works on all three platforms, backed by local storage on the web, so using it
everywhere would be the smallest change. But it would also give up the atomic temp-file-and-rename
write that protects the training history on mobile, and push a growing JSON document into
`NSUserDefaults`.

## Decision

Put a `DocumentStore` interface in front of storage and pick the implementation by conditional
import:

```dart
export 'document_store_io.dart'
    if (dart.library.js_interop) 'document_store_web.dart';
```

Mobile keeps the file with the atomic rename. Web uses `shared_preferences`, where a local-storage
write either lands whole or does not happen, so there is no partial write to guard against.

## Consequences

`dart.library.js_interop` is only defined when compiling for the web, so a mobile build never sees
the browser implementation and a web build never sees `dart:io`.

Nothing outside `document_store_io.dart` may import `path_provider`, or the web build breaks again.

Repositories take an injected `DocumentStore`, which is also how their tests supply a real
temporary directory.
