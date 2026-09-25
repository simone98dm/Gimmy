import 'models/workout_session.dart';

/// The run [current] is measured against: the latest earlier session of the
/// same plan name in which at least one step was done.
///
/// By name, not plan id: re-importing the same workout gives it a new id, and
/// the history should carry on across that. A session that was opened and
/// left with nothing done is no baseline.
WorkoutSession? previousRun(
  List<WorkoutSession> history,
  WorkoutSession current,
) {
  WorkoutSession? latest;
  for (final session in history) {
    if (session.id == current.id ||
        session.planName != current.planName ||
        session.stepsCompleted == 0 ||
        !session.startedAt.isBefore(current.startedAt)) {
      continue;
    }
    if (latest == null || session.startedAt.isAfter(latest.startedAt)) {
      latest = session;
    }
  }
  return latest;
}

/// How [current] differs from [previous]. Changes, not verdicts: the screen
/// decides how (and whether) to colour them.
class SessionComparison {
  const SessionComparison._(this.current, this.previous);

  factory SessionComparison.of(
    WorkoutSession current,
    WorkoutSession previous,
  ) => SessionComparison._(current, previous);

  final WorkoutSession current;
  final WorkoutSession previous;

  int get activeSecondsChange =>
      current.totalActiveSeconds - previous.totalActiveSeconds;

  int get doneChange => current.stepsCompleted - previous.stepsCompleted;

  /// Null unless both sessions recorded heart rate.
  int? get averageBpmChange => _change(current.averageBpm, previous.averageBpm);

  /// The change on step [index], or null when there is nothing honest to
  /// compare: no records last time, or a different step in that place.
  StepComparison? step(int index) {
    if (index >= current.steps.length || index >= previous.steps.length) {
      return null;
    }
    final now = current.steps[index];
    final then = previous.steps[index];
    if (now.name != then.name) return null;
    return StepComparison(
      secondsChange: now.activeSeconds - then.activeSeconds,
      averageBpmChange: _change(now.averageBpm, then.averageBpm),
      previousOutcome: then.outcome,
    );
  }

  static int? _change(int? now, int? then) =>
      now == null || then == null ? null : now - then;
}

/// One step, against the same step last time.
class StepComparison {
  const StepComparison({
    required this.secondsChange,
    required this.averageBpmChange,
    required this.previousOutcome,
  });

  final int secondsChange;
  final int? averageBpmChange;
  final StepOutcome previousOutcome;
}
