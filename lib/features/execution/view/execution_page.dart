import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../data/models/plan_step.dart';
import '../../heart_rate/bloc/heart_rate_bloc.dart';
import '../bloc/execution_bloc.dart';
import '../widgets/completion_summary.dart';
import '../widgets/execution_controls.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExecutionBloc, ExecutionState>(
      // Sound and vibration live here rather than in the bloc: they are
      // feedback about a state change, not part of it, and a bloc test should
      // not have to silence a speaker.
      listener: (context, state) {
        final cue = cueFor(_previous, state);
        _previous = state;
        if (cue != null && widget.areCuesEnabled) WorkoutCues.play(cue);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
      child: Column(
        children: [
          const SizedBox(height: GimmySpacing.md),
          _ProgressCard(state: state),
          const SizedBox(height: GimmySpacing.md),
          _StageCard(state: state, step: step),
          const SizedBox(height: GimmySpacing.md),
          _NextUpCard(state: state),
          if (step.notes case final notes?) ...[
            const SizedBox(height: GimmySpacing.md),
            _FormTipCard(notes: notes),
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
    final fraction = state.stepNumber / state.totalSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GimmySpacing.md),
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
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          ClipRRect(
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
          const SizedBox(height: GimmySpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SESSION PACING',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                '${(fraction * 100).round()}% COMPLETE',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _TypeChip(step: step)),
              const SizedBox(width: GimmySpacing.xs),
              _TargetChip(step: step),
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          Text(
            step.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            _instruction(step),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: GimmySpacing.xs),
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
    StepType.timer => 'Hold until the timer runs out',
    StepType.reps => 'Tap Next when the set is done',
    StepType.open => 'Tap Next whenever you are ready',
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

/// The left chip: what kind of step this is.
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.step});

  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final (icon, label) = switch (step.type) {
      StepType.timer => (Icons.timer_outlined, 'Timed'),
      StepType.reps => (Icons.repeat, 'Repetitions'),
      StepType.open => (Icons.all_inclusive, 'Open ended'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: GimmySpacing.xs),
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: tokens.labelMono.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The right chip: what this step is asking for.
class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.step});

  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final tokens = GimmyTokens.of(context);
    final amber = tokens.intensityRest;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14, color: amber),
          const SizedBox(width: 2),
          Text(
            'Target: ${stepTarget(step)}',
            style: tokens.labelMono.copyWith(color: amber),
          ),
        ],
      ),
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
      StepType.reps => '${step.repCount}',
      StepType.open => '––',
    };

    return TimerRing(
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
          const SizedBox(height: 2),
          Text(
            readout,
            style: tokens.metricDisplayMobile.copyWith(
              color: step.isTimer && color == tokens.timerCritical
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: GimmySpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GimmySpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.8,
              ),
              borderRadius: BorderRadius.circular(GimmyRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(width: GimmySpacing.xs),
                Text(
                  'STEP ${state.stepNumber} / ${state.totalSteps}',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurface,
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

/// What is coming, plus the way out of the workout.
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
                  'NEXT UP IN ROUTINE',
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
          const SizedBox(width: GimmySpacing.xs),
          _FinishButton(),
        ],
      ),
    );
  }
}

/// Ends the workout early. Routed through the same confirmation as leaving,
/// because steps are still outstanding and the session is recorded as
/// abandoned either way.
class _FinishButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: GimmyRadii.cell,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GimmySpacing.sm,
            vertical: GimmySpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FINISH',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: GimmySpacing.xs),
              Icon(Icons.flag, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXERCISE CUE',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GimmySpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GimmyRadii.pill),
                ),
                child: Text(
                  'Form Tip',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          Text(notes, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
