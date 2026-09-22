part of 'import_bloc.dart';

enum ImportStatus {
  /// Waiting for the user to pick a file.
  idle,

  /// Reading and validating the chosen file.
  parsing,

  /// A valid plan is on screen, waiting to be confirmed.
  preview,

  /// Writing the confirmed plan to storage.
  saving,

  /// Saved and active. The page should leave for the Dashboard.
  saved,

  /// The file was rejected. [ImportState.errorMessage] says why.
  failure,
}

class ImportState extends Equatable {
  const ImportState({
    this.status = ImportStatus.idle,
    this.plan,
    this.filename,
    this.errorMessage,
  });

  final ImportStatus status;

  /// Set only while previewing or saving. A rejected file leaves this null, so
  /// no partial plan can leak into the UI or into storage.
  final Plan? plan;

  /// The name of the file the user picked, kept for the error message.
  final String? filename;

  final String? errorMessage;

  bool get isBusy =>
      status == ImportStatus.parsing || status == ImportStatus.saving;

  bool get canConfirm => status == ImportStatus.preview && plan != null;

  @override
  List<Object?> get props => [status, plan, filename, errorMessage];
}
