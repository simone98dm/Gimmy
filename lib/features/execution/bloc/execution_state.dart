part of 'execution_bloc.dart';

enum ExecutionStatus {
  /// Still going.
  running,

  /// Every step has been played or skipped.
  completed,

  /// The user left before the end.
  abandoned,
}

/// What the primary button does right now.
enum PrimaryAction {
  /// Timer step, stopped or paused.
  play,

  /// Timer step, counting down.
  pause,

  /// Reps or open step — only the user knows when it is done.
  next,
}

class ExecutionState extends Equatable {
  const ExecutionState({
    required this.plan,
    required this.sessionId,
    required this.startedAt,
    this.currentIndex = 0,
    this.remainingSeconds = 0,
    this.isTimerRunning = false,
    this.totalActiveSeconds = 0,
    this.stepsCompleted = 0,
    this.stepsSkipped = 0,
    this.status = ExecutionStatus.running,
  });

  final Plan plan;
  final String sessionId;
  final DateTime startedAt;

  /// Index into [Plan.steps]. Past the end only while finishing.
  final int currentIndex;

  /// Seconds left on the current timer step. Zero on reps and open steps.
  final int remainingSeconds;

  /// A timer step never starts on its own — this is false until Play, and
  /// false again on every step after an automatic advance.
  final bool isTimerRunning;

  /// Seconds the workout was actually being worked, excluding time a timer
  /// spent stopped or paused. Reps and open steps always count: standing at a
  /// machine doing twelve reps is not idle time.
  final int totalActiveSeconds;

  final int stepsCompleted;
  final int stepsSkipped;
  final ExecutionStatus status;

  bool get isRunning => status == ExecutionStatus.running;
  bool get isFinished => !isRunning;

  /// Null once the workout is over.
  PlanStep? get currentStep =>
      currentIndex < plan.steps.length ? plan.steps[currentIndex] : null;

  PlanStep? get nextStep => currentIndex + 1 < plan.steps.length
      ? plan.steps[currentIndex + 1]
      : null;

  /// 1-based, for "Step 4 of 54".
  int get stepNumber => (currentIndex + 1).clamp(1, plan.steps.length);

  int get totalSteps => plan.steps.length;

  /// How far through the step the countdown is, 1.0 down to 0.0.
  double get timerProgress {
    final total = currentStep?.durationSeconds ?? 0;
    if (total <= 0) return 0;
    return (remainingSeconds / total).clamp(0.0, 1.0);
  }

  PrimaryAction get primaryAction {
    final step = currentStep;
    if (step == null || !step.isTimer) return PrimaryAction.next;
    return isTimerRunning ? PrimaryAction.pause : PrimaryAction.play;
  }

  /// −10s applies to timer steps only.
  bool get canAdjustTimer =>
      isRunning && (currentStep?.isTimer ?? false) && remainingSeconds > 0;

  ExecutionState copyWith({
    int? currentIndex,
    int? remainingSeconds,
    bool? isTimerRunning,
    int? totalActiveSeconds,
    int? stepsCompleted,
    int? stepsSkipped,
    ExecutionStatus? status,
  }) {
    return ExecutionState(
      plan: plan,
      sessionId: sessionId,
      startedAt: startedAt,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      stepsSkipped: stepsSkipped ?? this.stepsSkipped,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    plan,
    sessionId,
    startedAt,
    currentIndex,
    remainingSeconds,
    isTimerRunning,
    totalActiveSeconds,
    stepsCompleted,
    stepsSkipped,
    status,
  ];
}
