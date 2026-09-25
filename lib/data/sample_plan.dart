import 'models/plan.dart';
import 'models/plan_step.dart';

/// The workout offered to someone who has no `.fit` file yet.
///
/// Short, and it walks through every kind of step the runner plays — a timer,
/// reps, rest, an open step — plus a form tip, so trying it shows the whole
/// app. Built in code rather than shipped as a `.fit` asset: it cannot fail
/// to parse, and it needs no encoder.
Plan buildSamplePlan({required String id, required DateTime importedAt}) =>
    Plan(
      id: id,
      name: 'gimmy sample',
      sourceFilename: Plan.sampleSourceFilename,
      importedAt: importedAt,
      steps: [
        PlanStep.timer(
          name: 'Warm-up',
          intensity: StepIntensity.warmup,
          durationSeconds: 120,
        ),
        PlanStep.reps(
          name: 'Squat',
          intensity: StepIntensity.active,
          repCount: 10,
          notes: 'Feet shoulder-width, chest up, knees tracking over toes.',
        ),
        PlanStep.timer(
          name: 'Rest',
          intensity: StepIntensity.rest,
          durationSeconds: 60,
        ),
        PlanStep.reps(
          name: 'Push-up',
          intensity: StepIntensity.active,
          repCount: 10,
        ),
        PlanStep.timer(
          name: 'Rest',
          intensity: StepIntensity.rest,
          durationSeconds: 60,
        ),
        PlanStep.timer(
          name: 'Plank',
          intensity: StepIntensity.active,
          durationSeconds: 45,
        ),
        PlanStep.open(name: 'Stretching', intensity: StepIntensity.cooldown),
      ],
    );
