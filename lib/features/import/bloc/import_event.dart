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

/// The user has no file yet and tapped "Try a sample workout".
class ImportSampleRequested extends ImportEvent {
  const ImportSampleRequested();
}

/// The user picked another demo for the exercise [name] in the preview, or
/// "No demo" when [exerciseId] is null.
class ImportExerciseChanged extends ImportEvent {
  const ImportExerciseChanged({required this.name, required this.exerciseId});

  final String name;
  final String? exerciseId;

  @override
  List<Object?> get props => [name, exerciseId];
}

/// The user tapped "Confirm & Save Plan" on a previewed plan.
class ImportConfirmed extends ImportEvent {
  const ImportConfirmed();
}

/// The user dismissed an error or discarded the preview.
class ImportReset extends ImportEvent {
  const ImportReset();
}
