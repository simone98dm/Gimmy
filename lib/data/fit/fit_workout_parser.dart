import 'dart:typed_data';

import '../models/plan.dart';
import '../models/plan_step.dart';
import 'fit_decoder.dart';
import 'fit_parse_exception.dart';
import 'workout_step_expander.dart';

/// Global message numbers, from Garmin's FIT profile.
abstract final class _Mesg {
  static const int fileId = 0;
  static const int workout = 26;
  static const int workoutStep = 27;
}

/// Field numbers within those messages.
abstract final class _Field {
  // file_id
  static const int fileType = 0;

  // workout
  static const int workoutName = 8;

  // workout_step
  static const int stepName = 0;
  static const int durationType = 1;
  static const int durationValue = 2;
  static const int targetValue = 4;
  static const int intensity = 7;
  static const int notes = 8;
  static const int messageIndex = 254;
}

/// `file_id.type` values.
abstract final class _FileType {
  static const int workout = 5;
}

/// `wkt_step_duration` values, the subset this app can act on.
abstract final class _DurationType {
  static const int time = 0;
  static const int repeatUntilStepsCompleted = 6;
  static const int reps = 29;
}

/// `intensity` values.
abstract final class _Intensity {
  static const int active = 0;
  static const int rest = 1;
  static const int warmup = 2;
  static const int cooldown = 3;
  static const int recovery = 4;
}

/// Turns the bytes of a Garmin `.fit` workout file into a [Plan].
///
/// Validation order matters: cheapest and most specific first, so the user gets
/// the most useful message. "Not a FIT file" and "a FIT file that is damaged"
/// are deliberately different answers — one means pick another file, the other
/// means export it again.
abstract final class FitWorkoutParser {
  static const String fileExtension = '.fit';

  /// Parses [bytes] into a plan named after [filename].
  ///
  /// Throws [FitParseException] for anything that is not a usable workout.
  /// Never returns a partially built plan.
  static Plan parse({
    required Uint8List bytes,
    required String filename,
    required String planId,
    required DateTime importedAt,
  }) {
    if (!filename.toLowerCase().endsWith(fileExtension)) {
      throw const FitParseException(FitParseFailure.wrongExtension);
    }

    if (!hasFitSignature(bytes)) {
      throw const FitParseException(FitParseFailure.notAFitFile);
    }

    final List<FitMessage> messages;
    try {
      messages = decodeFitMessages(bytes);
    } on FitDecodeException catch (error) {
      throw FitParseException(FitParseFailure.corrupt, error.message);
    } on RangeError catch (error) {
      throw FitParseException(FitParseFailure.corrupt, '$error');
    }

    final fileId = _first(messages, _Mesg.fileId);
    final fileType = fileId?.integer(_Field.fileType);
    if (fileType != _FileType.workout) {
      throw FitParseException(
        FitParseFailure.notAWorkoutFile,
        'file_id.type is $fileType',
      );
    }

    final workout = _first(messages, _Mesg.workout);
    if (workout == null) {
      throw const FitParseException(
        FitParseFailure.notAWorkoutFile,
        'No workout message',
      );
    }

    final stepMessages = messages
        .where((m) => m.globalMessageNumber == _Mesg.workoutStep)
        .toList();
    if (stepMessages.isEmpty) {
      throw const FitParseException(FitParseFailure.noSteps);
    }

    final steps = expandRepeats(_toRawSteps(stepMessages));
    if (steps.isEmpty) {
      throw const FitParseException(
        FitParseFailure.noSteps,
        'Every step expanded away',
      );
    }

    return Plan(
      id: planId,
      name: _planName(workout.string(_Field.workoutName), filename),
      sourceFilename: filename,
      importedAt: importedAt,
      steps: steps,
    );
  }

  static FitMessage? _first(List<FitMessage> messages, int globalNumber) {
    for (final message in messages) {
      if (message.globalMessageNumber == globalNumber) return message;
    }
    return null;
  }

  static String _planName(String? workoutName, String filename) {
    final trimmed = workoutName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    // Unnamed workouts exist. The filename is the next best label.
    return filename.replaceAll(RegExp(r'\.fit$', caseSensitive: false), '');
  }

  /// Sorted by `message_index`, because repeat steps jump to an index and the
  /// order messages happen to sit in the file is not guaranteed to match.
  static List<RawStep> _toRawSteps(List<FitMessage> messages) {
    final sorted = [...messages]
      ..sort(
        (a, b) => (a.integer(_Field.messageIndex) ?? 0).compareTo(
          b.integer(_Field.messageIndex) ?? 0,
        ),
      );

    return [
      for (var position = 0; position < sorted.length; position++)
        _toRawStep(sorted[position], position),
    ];
  }

  static RawStep _toRawStep(FitMessage message, int position) {
    final messageIndex = message.integer(_Field.messageIndex) ?? position;
    final durationType = message.integer(_Field.durationType);

    if (durationType == _DurationType.repeatUntilStepsCompleted) {
      return RawStep.repeat(
        messageIndex: messageIndex,
        // For a repeat step, duration_value is the index to jump back to and
        // target_value is how many times the block runs in total.
        repeatFromIndex: message.integer(_Field.durationValue) ?? 0,
        repeatCount: (message.integer(_Field.targetValue) ?? 1).clamp(
          1,
          1 << 20,
        ),
      );
    }

    return RawStep.exercise(
      messageIndex: messageIndex,
      step: _toPlanStep(message, position, durationType),
    );
  }

  static PlanStep _toPlanStep(
    FitMessage message,
    int position,
    int? durationType,
  ) {
    final name = _stepName(message.string(_Field.stepName), position);
    final intensity = _toIntensity(message.integer(_Field.intensity));
    final notes = message.string(_Field.notes)?.trim();
    final durationValue = message.integer(_Field.durationValue);

    if (durationType == _DurationType.time &&
        durationValue != null &&
        durationValue > 0) {
      return PlanStep.timer(
        name: name,
        intensity: intensity,
        // A time duration is stored in milliseconds.
        durationSeconds: (durationValue / 1000).round(),
        notes: notes,
      );
    }

    if (durationType == _DurationType.reps &&
        durationValue != null &&
        durationValue > 0) {
      return PlanStep.reps(
        name: name,
        intensity: intensity,
        repCount: durationValue,
        notes: notes,
      );
    }

    // Everything else — `open`, plus the duration types this app has no UI for
    // (distance, calories, heart rate, power) — becomes a step the user ends by
    // tapping Next. Dropping them would silently shorten the workout, which is
    // worse than showing a step without a target.
    return PlanStep.open(name: name, intensity: intensity, notes: notes);
  }

  static String _stepName(String? name, int position) {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return 'Step ${position + 1}';
  }

  /// FIT has seven intensities; the app shows four.
  static StepIntensity _toIntensity(int? intensity) => switch (intensity) {
    _Intensity.rest || _Intensity.recovery => StepIntensity.rest,
    _Intensity.warmup => StepIntensity.warmup,
    _Intensity.cooldown => StepIntensity.cooldown,
    _Intensity.active => StepIntensity.active,
    // interval, other, and anything unrecognised read as work.
    _ => StepIntensity.active,
  };
}
