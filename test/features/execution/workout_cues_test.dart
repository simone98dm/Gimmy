import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/workout_cues.dart';

void main() {
  final plan = Plan(
    id: 'plan-1',
    name: 'Test Plan',
    sourceFilename: 'test.fit',
    importedAt: DateTime(2026, 9, 22),
    steps: [
      PlanStep.timer(
        name: 'Plank',
        durationSeconds: 30,
        intensity: StepIntensity.active,
      ),
      PlanStep.reps(
        name: 'Squats',
        repCount: 12,
        intensity: StepIntensity.active,
      ),
    ],
  );

  final start = ExecutionState(
    plan: plan,
    sessionId: 'session-1',
    startedAt: DateTime(2026, 9, 22),
    remainingSeconds: 30,
  );

  test('advancing to the next step asks for the step cue', () {
    expect(cueFor(start, start.copyWith(currentIndex: 1)), WorkoutCue.step);
  });

  test('a tick within the same step asks for nothing', () {
    expect(cueFor(start, start.copyWith(remainingSeconds: 29)), isNull);
  });

  test('finishing asks for the completion cue, not the step cue', () {
    final finished = start.copyWith(
      currentIndex: 2,
      status: ExecutionStatus.completed,
    );

    expect(cueFor(start, finished), WorkoutCue.complete);
    // And only once: the summary can rebuild without beeping again.
    expect(cueFor(finished, finished), isNull);
  });

  test('abandoning stays silent', () {
    final abandoned = start.copyWith(status: ExecutionStatus.abandoned);

    expect(cueFor(start, abandoned), isNull);
  });
}
