import '../../data/models/plan_step.dart';
import 'duration_format.dart';

/// The human-readable target of a step: a duration, a rep count, or nothing.
///
/// Pure, so the workout logic can snapshot it into a session record without
/// reaching into a widget file.
String stepTarget(PlanStep step) => switch (step.type) {
  StepType.timer => DurationFormat.clock(
    Duration(seconds: step.durationSeconds!),
  ),
  StepType.reps => '${step.repCount} reps',
  StepType.open => 'Open',
};
