import 'package:equatable/equatable.dart';

import 'plan_step.dart';

/// What the user did with a step they reached.
enum StepOutcome {
  done,
  skipped;

  static StepOutcome fromName(String name) => StepOutcome.values.firstWhere(
    (v) => v.name == name,
    orElse: () => throw FormatException('Unknown step outcome "$name"'),
  );
}

/// One step of a session as it actually went.
///
/// Name and target are snapshotted, like the session's plan name, so the
/// record stays readable after the plan is replaced.
class StepRecord extends Equatable {
  const StepRecord({
    required this.name,
    required this.target,
    required this.intensity,
    required this.outcome,
    required this.activeSeconds,
    this.averageBpm,
  });

  final String name;

  /// "10 reps", "01:00" — already formatted, since the step itself may be gone.
  final String target;
  final StepIntensity intensity;
  final StepOutcome outcome;

  /// Seconds worked on this step, paused time excluded.
  final int activeSeconds;

  /// Null when no heart-rate sensor reported during the step.
  final int? averageBpm;

  Map<String, dynamic> toJson() => {
    'name': name,
    'target': target,
    'intensity': intensity.name,
    'outcome': outcome.name,
    'activeSeconds': activeSeconds,
    if (averageBpm != null) 'averageBpm': averageBpm,
  };

  factory StepRecord.fromJson(Map<String, dynamic> json) => StepRecord(
    name: json['name'] as String,
    target: json['target'] as String,
    intensity: StepIntensity.fromName(json['intensity'] as String),
    outcome: StepOutcome.fromName(json['outcome'] as String),
    activeSeconds: json['activeSeconds'] as int,
    averageBpm: json['averageBpm'] as int?,
  );

  @override
  List<Object?> get props => [
    name,
    target,
    intensity,
    outcome,
    activeSeconds,
    averageBpm,
  ];
}
