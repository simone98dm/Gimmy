import 'package:equatable/equatable.dart';

/// How a step ends.
enum StepType {
  /// Counts down [PlanStep.durationSeconds] and then advances on its own.
  timer,

  /// Shows a rep target and waits for the user to tap Next.
  reps,

  /// No target at all — the file says "go until you decide to stop".
  /// Advances on Next, exactly like [reps], but shows no count.
  open;

  static StepType fromName(String name) => StepType.values.firstWhere(
    (v) => v.name == name,
    orElse: () => throw FormatException('Unknown step type "$name"'),
  );
}

/// What the step is for. Drives the color of the step in the UI.
///
/// FIT defines three more intensities than the app cares about; the parser
/// folds `recovery` into [rest] and `interval`/`other` into [active].
enum StepIntensity {
  active,
  rest,
  warmup,
  cooldown;

  static StepIntensity fromName(String name) => StepIntensity.values.firstWhere(
    (v) => v.name == name,
    orElse: () => throw FormatException('Unknown intensity "$name"'),
  );
}

/// One step of a workout, already flattened out of any FIT repeat block.
///
/// Immutable: expanding, reordering or editing a plan produces new steps.
class PlanStep extends Equatable {
  const PlanStep({
    required this.name,
    required this.type,
    required this.intensity,
    this.durationSeconds,
    this.repCount,
    this.notes,
  });

  /// Builds a timer step, validating that it has a usable duration.
  factory PlanStep.timer({
    required String name,
    required StepIntensity intensity,
    required int durationSeconds,
    String? notes,
  }) {
    if (durationSeconds <= 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'A timer step needs a positive duration',
      );
    }
    return PlanStep(
      name: name,
      type: StepType.timer,
      intensity: intensity,
      durationSeconds: durationSeconds,
      notes: notes,
    );
  }

  /// Builds an open-ended step: no timer, no rep target, advanced by the user.
  factory PlanStep.open({
    required String name,
    required StepIntensity intensity,
    String? notes,
  }) {
    return PlanStep(
      name: name,
      type: StepType.open,
      intensity: intensity,
      notes: notes,
    );
  }

  /// Builds a reps step, validating that it has a usable rep count.
  factory PlanStep.reps({
    required String name,
    required StepIntensity intensity,
    required int repCount,
    String? notes,
  }) {
    if (repCount <= 0) {
      throw ArgumentError.value(
        repCount,
        'repCount',
        'A reps step needs a positive rep count',
      );
    }
    return PlanStep(
      name: name,
      type: StepType.reps,
      intensity: intensity,
      repCount: repCount,
      notes: notes,
    );
  }

  final String name;
  final StepType type;
  final StepIntensity intensity;

  /// Set when [type] is [StepType.timer], null otherwise.
  final int? durationSeconds;

  /// Set when [type] is [StepType.reps], null otherwise.
  final int? repCount;

  /// Free-text coaching notes from the FIT file. Often long, often not English.
  final String? notes;

  bool get isTimer => type == StepType.timer;
  bool get isReps => type == StepType.reps;
  bool get isOpen => type == StepType.open;

  /// True when the step ends because the user says so, not because a clock ran
  /// out. Drives the primary button's Next-vs-Play behaviour.
  bool get isUserAdvanced => !isTimer;

  /// Seconds this step contributes to a plan's estimated duration.
  ///
  /// Reps steps have no duration in the file, so the caller supplies an
  /// assumption. See `AppConfig.estimatedSecondsPerRep`.
  /// An open step contributes nothing — there is no basis for a guess.
  int estimatedSeconds({required int secondsPerRep}) => switch (type) {
    StepType.timer => durationSeconds!,
    StepType.reps => repCount! * secondsPerRep,
    StepType.open => 0,
  };

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'intensity': intensity.name,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (repCount != null) 'repCount': repCount,
    if (notes != null) 'notes': notes,
  };

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    final type = StepType.fromName(json['type'] as String);
    final name = json['name'] as String;
    final intensity = StepIntensity.fromName(json['intensity'] as String);
    final notes = json['notes'] as String?;

    return switch (type) {
      StepType.timer => PlanStep.timer(
        name: name,
        intensity: intensity,
        durationSeconds: json['durationSeconds'] as int,
        notes: notes,
      ),
      StepType.reps => PlanStep.reps(
        name: name,
        intensity: intensity,
        repCount: json['repCount'] as int,
        notes: notes,
      ),
      StepType.open => PlanStep.open(
        name: name,
        intensity: intensity,
        notes: notes,
      ),
    };
  }

  PlanStep copyWith({
    String? name,
    StepIntensity? intensity,
    int? durationSeconds,
    int? repCount,
    String? notes,
  }) {
    return PlanStep(
      name: name ?? this.name,
      type: type,
      intensity: intensity ?? this.intensity,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      repCount: repCount ?? this.repCount,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    name,
    type,
    intensity,
    durationSeconds,
    repCount,
    notes,
  ];
}
