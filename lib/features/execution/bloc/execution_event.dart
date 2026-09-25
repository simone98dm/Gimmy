part of 'execution_bloc.dart';

sealed class ExecutionEvent extends Equatable {
  const ExecutionEvent();

  @override
  List<Object?> get props => const [];
}

/// The page opened. Records the session — this is what counts for the streak,
/// whether or not the workout is finished.
class ExecutionStarted extends ExecutionEvent {
  const ExecutionStarted();
}

/// The one context-dependent button: Play, Pause, or Next.
class ExecutionPrimaryPressed extends ExecutionEvent {
  const ExecutionPrimaryPressed();
}

/// Move on without doing this step; it is recorded as skipped.
class ExecutionSkipped extends ExecutionEvent {
  const ExecutionSkipped();
}

/// Puts back the step just marked done or skipped — even the last one, which
/// reopens a finished workout.
class ExecutionUndone extends ExecutionEvent {
  const ExecutionUndone();
}

/// The −10s control.
class ExecutionTimerAdjusted extends ExecutionEvent {
  const ExecutionTimerAdjusted();
}

/// One second passed.
class ExecutionTicked extends ExecutionEvent {
  const ExecutionTicked();
}

/// The user confirmed leaving mid-workout.
class ExecutionAbandoned extends ExecutionEvent {
  const ExecutionAbandoned();
}
