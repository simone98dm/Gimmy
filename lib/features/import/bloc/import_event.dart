part of 'import_bloc.dart';

sealed class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => const [];
}

/// The user tapped "Select .FIT File".
class ImportFileRequested extends ImportEvent {
  const ImportFileRequested();
}

/// The user tapped "Confirm & Save Plan" on a previewed plan.
class ImportConfirmed extends ImportEvent {
  const ImportConfirmed();
}

/// The user dismissed an error or discarded the preview.
class ImportReset extends ImportEvent {
  const ImportReset();
}
