import 'package:equatable/equatable.dart';

import 'plan_step.dart';

/// A workout plan imported from a Garmin `.fit` workout file.
///
/// [steps] is already flat: FIT repeat blocks have been expanded, so the list
/// is exactly what the user will walk through, in order.
class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.name,
    required this.sourceFilename,
    required this.importedAt,
    required this.steps,
  });

  final String id;

  /// `workout.wkt_name` from the file, e.g. "Full Body Sample".
  final String name;

  /// The file the plan came from, shown in the import preview and settings.
  final String sourceFilename;

  final DateTime importedAt;

  final List<PlanStep> steps;

  int get stepCount => steps.length;

  /// Sum of every step's duration, with reps steps estimated.
  ///
  /// This is a preview figure only — a real session's length depends on how
  /// fast the user gets through the reps steps.
  Duration estimatedDuration({required int secondsPerRep}) => Duration(
    seconds: steps.fold(
      0,
      (total, step) =>
          total + step.estimatedSeconds(secondsPerRep: secondsPerRep),
    ),
  );

  /// The distinct working exercises, in the order they first appear.
  List<String> get exerciseNames {
    final seen = <String>{};
    return [
      for (final step in steps)
        if (step.intensity == StepIntensity.active && seen.add(step.name))
          step.name,
    ];
  }

  /// Estimated seconds spent at each intensity, for the intensity mix.
  Map<StepIntensity, int> secondsByIntensity({required int secondsPerRep}) => {
    for (final intensity in StepIntensity.values)
      intensity: steps
          .where((s) => s.intensity == intensity)
          .fold(
            0,
            (total, s) =>
                total + s.estimatedSeconds(secondsPerRep: secondsPerRep),
          ),
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceFilename': sourceFilename,
    'importedAt': importedAt.toIso8601String(),
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory Plan.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    if (rawSteps is! List) {
      throw const FormatException('Plan is missing its steps');
    }
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceFilename: json['sourceFilename'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
      steps: List.unmodifiable(
        rawSteps.map((s) => PlanStep.fromJson(s as Map<String, dynamic>)),
      ),
    );
  }

  Plan copyWith({
    String? id,
    String? name,
    String? sourceFilename,
    DateTime? importedAt,
    List<PlanStep>? steps,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFilename: sourceFilename ?? this.sourceFilename,
      importedAt: importedAt ?? this.importedAt,
      steps: steps ?? this.steps,
    );
  }

  @override
  List<Object?> get props => [id, name, sourceFilename, importedAt, steps];
}
