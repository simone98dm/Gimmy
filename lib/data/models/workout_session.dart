import 'package:equatable/equatable.dart';

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

  bool get isFinished => status != null;

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
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final endedAt = json['endedAt'] as String?;
    final status = json['status'] as String?;
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
    );
  }

  WorkoutSession copyWith({
    DateTime? endedAt,
    int? totalActiveSeconds,
    SessionStatus? status,
    int? stepsCompleted,
    int? stepsSkipped,
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
  ];
}
