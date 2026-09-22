# 4. An unfiltered file picker

Date: 2026-09-22

## Status

Accepted.

## Context

The natural way to ask for a `.fit` file is `FileType.custom` with `allowedExtensions: ['fit']`.

On iOS this produces a picker in which nothing can be selected. `file_picker` builds the document
picker's accepted types by asking the system to resolve each extension to a UTI, and it skips any
that resolve to a dynamic `dyn.…` identifier. iOS has no registered UTI for `.fit`, so the list
comes back empty, and `UIDocumentPickerViewController` with an empty type list greys out every file
on screen. The picker opens and nothing happens — no error to explain it.

Android is unaffected: it falls back to `*/*` when an extension is unknown.

Declaring the type in `Info.plist` does fix it, and was tried — LaunchServices then resolves `fit`
to `com.garmin.fit` and the filter works. But it makes the app's only entry point depend on a
LaunchServices registration, and the failure mode is a dead end with no message.

## Decision

Open the picker unfiltered (`FileType.any`) and let the parser do the rejecting.

## Consequences

The user sees every file rather than only `.fit` ones. Picking the wrong thing produces a clear,
specific error.

Nothing is less safe. The extension filter was only ever a convenience — a renamed file sailed
through it — and validation has always been the parser's job: extension, `.FIT` signature, CRC,
and `file_id.type == workout`.

A comment on `pickFitFile` records this, so the filter does not get helpfully restored later.
