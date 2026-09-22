import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A `.fit` file the user chose, already read into memory.
///
/// Workout files are a couple of kilobytes, so there is no reason to stream.
class PickedFitFile {
  const PickedFitFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Asks the user for a `.fit` file. Returns null when they cancel.
///
/// Typedef rather than a class so the import bloc can be tested without a
/// platform channel.
typedef FitFilePicker = Future<PickedFitFile?> Function();

/// The real picker.
///
/// Deliberately unfiltered. Filtering to `.fit` on iOS means
/// `FileType.custom` + `allowedExtensions: ['fit']`, and iOS has no registered
/// UTI for that extension: `file_picker` drops extensions that resolve to a
/// dynamic `dyn.…` identifier, so the accepted-types list comes back empty and
/// `UIDocumentPickerViewController` greys out every file on screen. The picker
/// opens and nothing can be selected — a dead end with no error to explain it.
/// (Android has no such problem; it falls back to `*/*`.)
///
/// Declaring the UTI in `Info.plist` does fix it, but only while LaunchServices
/// has the app's declaration registered, which is a fragile thing to hang the
/// one entry point to the app on. So the picker shows everything and
/// `FitWorkoutParser` does the rejecting: it checks the extension, the `.FIT`
/// signature, the CRC, and that the file is a *workout* rather than an activity.
/// Nothing is less safe — the filter was only ever a convenience, since a
/// renamed file would sail through it anyway.
Future<PickedFitFile?> pickFitFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
  );

  final file = result?.files.singleOrNull;
  if (file == null) return null;

  final bytes =
      file.bytes ??
      (file.path == null ? null : await File(file.path!).readAsBytes());
  if (bytes == null) return null;

  return PickedFitFile(name: file.name, bytes: bytes);
}
