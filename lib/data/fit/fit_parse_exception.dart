/// Why a `.fit` file could not become a [Plan].
///
/// Every case is something the user can act on, so [message] is written for
/// them, not for a log.
enum FitParseFailure {
  wrongExtension,
  notAFitFile,
  corrupt,
  notAWorkoutFile,
  noSteps,
  tooManySteps,
  unreadable;

  String get message => switch (this) {
    wrongExtension =>
      'That is not a .fit file. Pick a Garmin workout .fit file.',
    notAFitFile => 'This file is not in the Garmin FIT format. Pick a Garmin workout .fit file.',
    corrupt => 'This .fit file is damaged and could not be read. Try exporting it from Garmin again.',
    notAWorkoutFile =>
      'This is a Garmin file, but not a workout — it looks like an activity or course. '
          'Pick a workout .fit file.',
    noSteps => 'This workout file contains no steps.',
    tooManySteps =>
      'This workout expands to more steps than Gimmy can handle. '
          'Pick a shorter workout.',
    unreadable =>
      'The file could not be read. Check that it still exists and try again.',
  };
}

/// Thrown by [FitWorkoutParser]. Carries a user-facing [FitParseFailure] plus
/// optional technical [details] for logs.
class FitParseException implements Exception {
  const FitParseException(this.failure, [this.details]);

  final FitParseFailure failure;
  final String? details;

  String get message => failure.message;

  @override
  String toString() =>
      'FitParseException(${failure.name})${details == null ? '' : ': $details'}';
}
