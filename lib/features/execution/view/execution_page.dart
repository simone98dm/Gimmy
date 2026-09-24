import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../data/models/plan_step.dart';
import '../../heart_rate/bloc/heart_rate_bloc.dart';
import '../bloc/execution_bloc.dart';
import '../widgets/completion_summary.dart';
import '../widgets/execution_controls.dart';
import '../widgets/execution_desktop.dart';
import '../widgets/live_dot.dart';
import '../widgets/metric_strip.dart';
import '../widgets/timer_ring.dart';
import '../workout_cues.dart';

/// Guides the user through the active plan, one step at a time.
///
/// Laid out to match the Stitch "Active Workout & Timer Modal" screen: a
/// telemetry card on top, then one stage card holding everything about the
/// current step — chips, title, the countdown dial, the metric strip and the
/// controls — then the next-up card and the form tip. The completion summary
/// arrives as a modal over the top of it, not as a separate page.
class ExecutionPage extends StatefulWidget {
  const ExecutionPage({
    super.key,
    required this.onDone,
    this.areCuesEnabled = true,
  });

  /// Leaves the workout, back to the Dashboard.
  final VoidCallback onDone;

  /// The user's Settings choice for step and completion cues.
  final bool areCuesEnabled;

  @override
  State<ExecutionPage> createState() => _ExecutionPageState();
}

class _ExecutionPageState extends State<ExecutionPage> {
  /// The last state the cues saw, so a listener call can tell what moved.
  late ExecutionState _previous = context.read<ExecutionBloc>().state;

  /// Skip sits beside the primary control, so a mis-tap has to be cheap.
  void _offerUndo(BuildContext context) {
    final bloc = context.read<ExecutionBloc>();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Step skipped'),
          duration: _undoWindow,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => bloc.add(const ExecutionSkipUndone()),
          ),
        ),
      );
  }

  static const _undoWindow = Duration(seconds: 4);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExecutionBloc, ExecutionState>(
      // Sound and vibration live here rather than in the bloc: they are
      // feedback about a state change, not part of it, and a bloc test should
      // not have to silence a speaker.
      listener: (context, state) {
        final cue = cueFor(_previous, state);
        final didJustSkip = state.canUndoSkip && !_previous.canUndoSkip;
        _previous = state;
        if (cue != null && widget.areCuesEnabled) WorkoutCues.play(cue);
        if (didJustSkip) _offerUndo(context);
        if (!state.canUndoSkip) {
          ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Positioned.fill(child: _Workout(state: state)),
            if (state.isFinished)
              Positioned.fill(
                child: CompletionSummary(state: state, onDone: widget.onDone),
              ),
          ],
        );
      },
    );
  }
}

class _Workout extends StatelessWidget {
  const _Workout({required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    // Past the last step there is nothing to draw underneath the summary.
    final step = state.currentStep ?? state.plan.steps.last;
    final stage = _StageCard(state: state, step: step);
    // Beside the stage card on a desktop, as the Stitch desktop screen has it.
    final aside = isDesktopLayout(context)
        ? [
            if (step.notes case final notes?) ...[
              _FormTipCard(notes: notes),
              const SizedBox(height: GimmySpacing.md),
            ],
            StepLogCard(state: state),
            const SizedBox(height: GimmySpacing.md),
            _NextUpCard(state: state),
          ]
        : [
            // The cue is about the set in progress, so it outranks what is next.
            if (step.notes case final notes?) ...[
              _FormTipCard(notes: notes),
              const SizedBox(height: GimmySpacing.md),
            ],
            _NextUpCard(state: state),
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
      child: Column(
        children: [
          const SizedBox(height: GimmySpacing.md),
          if (isDesktopLayout(context))
            ExecutionTelemetryCard(state: state)
          else
            _ProgressCard(state: state),
          const SizedBox(height: GimmySpacing.md),
          if (isDesktopLayout(context))
            DesktopColumns(
              start: stage,
              end: Column(children: aside),
            )
          else ...[
            stage,
            const SizedBox(height: GimmySpacing.md),
            ...aside,
          ],
          const SizedBox(height: GimmySpacing.lg),
        ],
      ),
    );
  }
}

/// Where the user is in the plan, and how far through.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    // Steps behind the user, so the first step reads 0%, not 5%.
    final fraction = state.currentIndex / state.totalSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        GimmySpacing.md,
        GimmySpacing.xs,
        GimmySpacing.xs,
        GimmySpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.card,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveDot(isLive: state.isTimerRunning),
              const SizedBox(width: GimmySpacing.xs),
              Expanded(
                child: Text(
                  'STEP ${state.stepNumber} OF ${state.totalSteps}',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _IntensityChip(intensity: state.currentStep?.intensity),
              const EndWorkoutButton(),
            ],
          ),
          const SizedBox(height: GimmySpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: GimmySpacing.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GimmyRadii.pill),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  theme.colorScheme.primaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: GimmySpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: GimmySpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(fraction * 100).round()}% DONE',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The prototype's "PRO FOCUS" pill, carrying something we actually know.
class _IntensityChip extends StatelessWidget {
  const _IntensityChip({required this.intensity});

  final StepIntensity? intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    if (intensity == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Text(
        intensity!.name.toUpperCase(),
        style: tokens.labelMono.copyWith(
          color: intensityColor(context, intensity!),
        ),
      ),
    );
  }
}

/// Everything about the current step, in one card.
class _StageCard extends StatelessWidget {
  const _StageCard({required this.state, required this.step});

  final ExecutionState state;
  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final bloc = context.read<ExecutionBloc>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            step.name,
            textAlign: TextAlign.center,
            // The desktop card has the room for the prototype's big title.
            style: isDesktopLayout(context)
                ? theme.textTheme.headlineLarge
                : theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            _instruction(step),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: GimmySpacing.md),
          _Dial(state: state, step: step),
          const SizedBox(height: GimmySpacing.md),
          const _Metrics(),
          ExecutionControls(
            state: state,
            onAdjust: () => bloc.add(const ExecutionTimerAdjusted()),
            onPrimary: () => bloc.add(const ExecutionPrimaryPressed()),
            onSkip: () => bloc.add(const ExecutionSkipped()),
          ),
        ],
      ),
    );
  }

  /// Fills the prototype's coaching-cue slot with something true of this step.
  static String _instruction(PlanStep step) => switch (step.type) {
    StepType.timer => switch (step.intensity) {
      StepIntensity.rest => 'Rest until the timer runs out',
      StepIntensity.warmup ||
      StepIntensity.cooldown => 'Easy pace until the timer runs out',
      StepIntensity.active => 'Keep going until the timer runs out',
    },
    StepType.reps => 'Tap Done when the set is finished',
    StepType.open => 'Tap Done whenever you are ready',
  };
}

/// The metric strip and the gap under it, both gone when there is nothing to
/// show.
class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    final isPaired = context.select(
      (HeartRateBloc bloc) => bloc.state.link != HeartRateLink.none,
    );
    final bpm = context.select((HeartRateBloc bloc) => bloc.state.bpm);
    if (!isPaired && !FeatureFlags.showAnyMetric) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: GimmySpacing.md),
      child: MetricStrip(showBpm: isPaired, bpm: bpm),
    );
  }
}

/// The countdown dial and its readout.
class _Dial extends StatelessWidget {
  const _Dial({required this.state, required this.step});

  final ExecutionState state;
  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final color = step.isTimer
        ? tokens.timerColorFor(
            remainingSeconds: state.remainingSeconds,
            totalSeconds: step.durationSeconds ?? 0,
          )
        : intensityColor(context, step.intensity);

    // The prototype changes this caption as the ring changes colour.
    final caption = switch (step.type) {
      StepType.timer when !state.isTimerRunning => 'PRESS PLAY',
      StepType.timer when color == tokens.timerCritical => 'FINAL PUSH!',
      StepType.timer when color == tokens.timerWarning => 'HOLD INTENSITY',
      StepType.timer => 'HOLD TIME',
      StepType.reps => 'REPETITIONS',
      StepType.open => 'NO TARGET',
    };

    final readout = switch (step.type) {
      StepType.timer => DurationFormat.clock(
        Duration(seconds: state.remainingSeconds),
      ),
      StepType.reps => '×${step.repCount}',
      StepType.open => '––',
    };

    final diameter = isDesktopLayout(context) ? 320.0 : 256.0;

    return TimerRing(
      diameter: diameter,
      progress: step.isTimer ? state.timerProgress : 1,
      color: step.isTimer && !state.isTimerRunning
          ? color.withValues(alpha: 0.4)
          : color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            textAlign: TextAlign.center,
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: GimmySpacing.xs),
          // Sized to the ring's inside, so a long countdown shrinks rather
          // than spilling over the stroke.
          SizedBox(
            width: diameter * 0.78,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                readout,
                style: tokens.metricDisplayMobile.copyWith(
                  color: step.isTimer && color == tokens.timerCritical
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What is coming next.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final next = state.nextStep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GimmySpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.card,
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: GimmyRadii.cell,
            ),
            child: Icon(
              next == null ? Icons.flag_outlined : Icons.fitness_center,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: GimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT UP',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  next?.name ?? 'Last step',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  next == null
                      ? 'Finish strong'
                      : '${stepTarget(next)} · ${next.intensity.name}',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The coaching notes carried in the FIT file.
class _FormTipCard extends StatelessWidget {
  const _FormTipCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FORM TIP',
            style: tokens.labelMono.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: GimmySpacing.sm),
          Text(notes, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
