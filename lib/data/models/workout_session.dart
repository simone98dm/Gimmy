import 'package:equatable/equatable.dart';

import '../../core/logging/app_log.dart';
import 'step_record.dart';

export 'step_record.dart';

/// How a session ended.
enum SessionStatus {
  /// The user reached the end of the plan.
  completed,

  /// The user left mid-workout and confirmed the exit.
  abandoned;

  static SessionStatus fromName(String name) => SessionStatus.values.firstWhere(
    (v) => v.name == name,
    orElse: () => throw FormatException('Unknown session status "$name"'),
  );
}

/// One run at a plan. Created the moment the Execution page opens — that is
/// what makes the day count toward the streak, whether or not it is finished.
class WorkoutSession extends Equatable {
  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    this.endedAt,
    this.totalActiveSeconds = 0,
    this.status,
    this.stepsCompleted = 0,
    this.stepsSkipped = 0,
    this.plannedSteps,
    this.steps = const [],
    this.averageBpm,
    this.maxBpm,
  });

  final String id;

  final String planId;

  /// The plan's name at the time of the session. Snapshotted so history stays
  /// readable after the plan is replaced by a new import.
  final String planName;

  final DateTime startedAt;

  /// Null while the session is still running.
  final DateTime? endedAt;

  /// Wall-clock seconds spent on the workout, excluding paused time.
  final int totalActiveSeconds;

  /// Null while the session is still running.
  final SessionStatus? status;

  final int stepsCompleted;
  final int stepsSkipped;

  /// How many steps the plan had. Null on sessions recorded before step
  /// records existed — which is how those are told apart.
  final int? plannedSteps;

  /// Every step reached, in order. Empty on older sessions.
  final List<StepRecord> steps;

  /// Heart rate over the session. Null when no sensor reported.
  final int? averageBpm;
  final int? maxBpm;

  bool get isFinished => status != null;

  bool get hasStepRecords => plannedSteps != null;

  /// Steps the session never got to: left early, or still running.
  int get stepsNotReached => hasStepRecords
      ? (plannedSteps! - steps.length).clamp(0, plannedSteps!)
      : 0;

  /// The calendar day this session belongs to, in local time, normalized to
  /// midnight. Both the streak and the calendar group on this.
  DateTime get localDay =>
      DateTime(startedAt.year, startedAt.month, startedAt.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'planName': planName,
    'startedAt': startedAt.toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
    'totalActiveSeconds': totalActiveSeconds,
    if (status != null) 'status': status!.name,
    'stepsCompleted': stepsCompleted,
    'stepsSkipped': stepsSkipped,
    if (plannedSteps != null) 'plannedSteps': plannedSteps,
    if (hasStepRecords) 'steps': [for (final step in steps) step.toJson()],
    if (averageBpm != null) 'averageBpm': averageBpm,
    if (maxBpm != null) 'maxBpm': maxBpm,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final endedAt = json['endedAt'] as String?;
    final status = json['status'] as String?;
    final steps = _stepsFromJson(json);
    return WorkoutSession(
      id: json['id'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: endedAt == null ? null : DateTime.parse(endedAt),
      totalActiveSeconds: json['totalActiveSeconds'] as int? ?? 0,
      status: status == null ? null : SessionStatus.fromName(status),
      stepsCompleted: json['stepsCompleted'] as int? ?? 0,
      stepsSkipped: json['stepsSkipped'] as int? ?? 0,
      plannedSteps: steps == null ? null : json['plannedSteps'] as int?,
      steps: steps ?? const [],
      averageBpm: json['averageBpm'] as int?,
      maxBpm: json['maxBpm'] as int?,
    );
  }

  /// The step records, or null when there are none or they cannot be read.
  ///
  /// A bad step list costs the session its detail, not its place in the
  /// history: the totals above it are still true.
  static List<StepRecord>? _stepsFromJson(Map<String, dynamic> json) {
    final raw = json['steps'];
    if (raw == null) return null;
    try {
      return List.unmodifiable(
        (raw as List).map(
          (e) => StepRecord.fromJson(e as Map<String, dynamic>),
        ),
      );
    } on Object catch (error) {
      AppLog.warning(
        'storage',
        'session ${json['id']} has unreadable step records, keeping its totals',
        error,
      );
      return null;
    }
  }

  WorkoutSession copyWith({
    DateTime? endedAt,
    int? totalActiveSeconds,
    SessionStatus? status,
    int? stepsCompleted,
    int? stepsSkipped,
    int? plannedSteps,
    List<StepRecord>? steps,
    int? averageBpm,
    int? maxBpm,
  }) {
    return WorkoutSession(
      id: id,
      planId: planId,
      planName: planName,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
      status: status ?? this.status,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      stepsSkipped: stepsSkipped ?? this.stepsSkipped,
      plannedSteps: plannedSteps ?? this.plannedSteps,
      steps: steps ?? this.steps,
      averageBpm: averageBpm ?? this.averageBpm,
      maxBpm: maxBpm ?? this.maxBpm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    planId,
    planName,
    startedAt,
    endedAt,
    totalActiveSeconds,
    status,
    stepsCompleted,
    stepsSkipped,
    plannedSteps,
    steps,
    averageBpm,
    maxBpm,
  ];
}
