import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../data/models/plan_step.dart';
import '../../heart_rate/bloc/heart_rate_bloc.dart';
import '../bloc/execution_bloc.dart';
import 'live_dot.dart';
import 'metric_strip.dart';
import 'timer_ring.dart';

/// The pieces of the current step that the phone and desktop runners share:
/// its heading, its dial and the live metrics under it.

/// The step name and what to do, cross-faded when the step changes.
///
/// Keyed by position, so the title fades instead of the new name snapping in
/// under a moving thumb. A live region, so a screen reader announces the new
/// step.
class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.index, required this.step});

  final int index;
  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: GimmyMotion.isReduced(context)
          ? Duration.zero
          : GimmyMotion.stateChange,
      switchInCurve: GimmyMotion.enter,
      switchOutCurve: GimmyMotion.exit,
      child: Semantics(
        key: ValueKey(index),
        liveRegion: true,
        child: Column(
          children: [
            Text(
              step.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: GimmySpacing.xs),
            Text(
              instructionFor(step),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fills the prototype's coaching-cue slot with something true of this step.
String instructionFor(PlanStep step) => switch (step.type) {
  StepType.timer => switch (step.intensity) {
    StepIntensity.rest => 'Rest until the timer runs out',
    StepIntensity.warmup ||
    StepIntensity.cooldown => 'Easy pace until the timer runs out',
    StepIntensity.active => 'Keep going until the timer runs out',
  },
  StepType.reps => 'Tap Done when the set is finished',
  StepType.open => 'Tap Done whenever you are ready',
};

/// What the dial shows: the time left, the rep target, or a dash.
String stepReadout(ExecutionState state, PlanStep step) => switch (step.type) {
  StepType.timer => DurationFormat.clock(
    Duration(seconds: state.remainingSeconds),
  ),
  StepType.reps => '×${step.repCount}',
  StepType.open => '––',
};

/// The countdown dial on a timer step; the bare target on any other.
///
/// A ring only where it counts down. On a reps or open step it would sit full
/// and still, drawing a meaning it does not have.
class StepDial extends StatelessWidget {
  const StepDial({
    super.key,
    required this.state,
    required this.step,
    required this.diameter,
  });

  final ExecutionState state;
  final PlanStep step;
  final double diameter;

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

    final readout = stepReadout(state, step);

    final face = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          textAlign: TextAlign.center,
          style: tokens.labelMono.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: GimmyType.capsTracking,
          ),
        ),
        const SizedBox(height: GimmySpacing.xs),
        // Sized to the ring's inside, so a long countdown shrinks rather than
        // spilling over the stroke.
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
    );

    if (!step.isTimer) {
      return SizedBox.square(
        dimension: diameter,
        child: Center(child: face),
      );
    }

    // Repaints every second while the rest of the page sits still.
    return RepaintBoundary(
      child: TimerRing(
        diameter: diameter,
        progress: state.timerProgress,
        color: state.isTimerRunning ? color : color.withValues(alpha: 0.4),
        child: face,
      ),
    );
  }
}

/// The metric strip and the gap under it, both gone when there is nothing to
/// show.
class LiveMetrics extends StatelessWidget {
  const LiveMetrics({super.key});

  /// Whether the strip shows at all, for layouts that budget its height.
  static bool isShown(BuildContext context) =>
      context.select(
        (HeartRateBloc bloc) => bloc.state.link != HeartRateLink.none,
      ) ||
      FeatureFlags.showAnyMetric;

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

/// Where the user is in the plan: step count, intensity, a thin bar.
class ProgressStrip extends StatelessWidget {
  const ProgressStrip({super.key, required this.state, this.trailing});

  final ExecutionState state;

  /// Right-aligned figures on the desktop strip.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    // Steps behind the user, so the first step reads empty, not 5%.
    final fraction = state.currentIndex / state.totalSteps;
    final intensity = state.currentStep?.intensity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GimmySpacing.gutter,
        GimmySpacing.ms,
        GimmySpacing.gutter,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              LiveDot(isLive: state.isTimerRunning),
              const SizedBox(width: GimmySpacing.sm),
              Expanded(
                child: Text(
                  'STEP ${state.stepNumber} OF ${state.totalSteps}',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: GimmyType.capsTracking,
                  ),
                ),
              ),
              if (intensity != null) IntensityChip(intensity: intensity),
              if (trailing != null) ...[
                const SizedBox(width: GimmySpacing.md),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(GimmyRadii.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: GimmySpacing.xs,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                theme.colorScheme.primaryContainer,
              ),
              semanticsLabel: 'Workout progress',
            ),
          ),
        ],
      ),
    );
  }
}

/// The prototype's "PRO FOCUS" pill, carrying something we actually know.
class IntensityChip extends StatelessWidget {
  const IntensityChip({super.key, required this.intensity});

  final StepIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: GimmySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Text(
        intensity.name.toUpperCase(),
        style: GimmyTokens.of(context).labelMono.copyWith(
          color: intensityColor(context, intensity),
          letterSpacing: GimmyType.capsTracking,
        ),
      ),
    );
  }
}

/// The step's coaching note, one tap away rather than a card of its own.
class FormTipLine extends StatefulWidget {
  const FormTipLine({super.key, required this.notes});

  final String notes;

  @override
  State<FormTipLine> createState() => _FormTipLineState();
}

class _FormTipLineState extends State<FormTipLine> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _isOpen = !_isOpen),
          icon: Icon(_isOpen ? Icons.expand_less : Icons.expand_more),
          label: const Text('Form tip'),
        ),
        if (_isOpen)
          Text(
            widget.notes,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
      ],
    );
  }
}
