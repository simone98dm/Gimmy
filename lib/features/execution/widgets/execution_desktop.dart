import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/gimmy_badge.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../data/models/plan_step.dart';
import '../bloc/execution_bloc.dart';
import 'execution_controls.dart';
import 'live_dot.dart';

/// The pieces of the Stitch desktop workout screen the phone layout does not
/// have, each fed by the running session rather than the prototype's
/// invented telemetry.

/// Across the top: live state and position, the session's figures, then the
/// progress bar.
class ExecutionTelemetryCard extends StatelessWidget {
  const ExecutionTelemetryCard({super.key, required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    // Steps behind the user, so the first step reads 0%, not 5%.
    final fraction = state.currentIndex / state.totalSteps;
    final step = state.currentStep;

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LiveDot(isLive: state.isTimerRunning),
              const SizedBox(width: GimmySpacing.xs),
              Text(
                state.isTimerRunning ? 'RUNNING' : 'PAUSED',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: GimmySpacing.md),
              Expanded(
                child: Text(
                  'STEP ${state.stepNumber} OF ${state.totalSteps}'
                  '${step == null ? '' : ' · ${step.name.toUpperCase()}'}',
                  overflow: TextOverflow.ellipsis,
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _Figure(
                icon: Icons.timer_outlined,
                label: 'Active',
                value: DurationFormat.clock(
                  Duration(seconds: state.totalActiveSeconds),
                ),
              ),
              const SizedBox(width: GimmySpacing.lg),
              _Figure(
                icon: Icons.check_circle_outline,
                label: 'Done',
                value: '${state.stepsCompleted}',
              ),
              const SizedBox(width: GimmySpacing.lg),
              _Figure(
                icon: Icons.skip_next_outlined,
                label: 'Skipped',
                value: '${state.stepsSkipped}',
                color: tokens.intensityRest,
              ),
              if (step != null) ...[
                const SizedBox(width: GimmySpacing.lg),
                GimmyBadge(
                  label: step.intensity.name,
                  color: intensityColor(context, step.intensity),
                ),
              ],
              const SizedBox(width: GimmySpacing.sm),
              const EndWorkoutButton(),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'WORKOUT PROGRESSION',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${(fraction * 100).round()}% DONE',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.xs),
          GimmyMeter(value: fraction, height: 8),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: GimmySpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: tokens.labelMono.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: tokens.metricMd.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A window on the plan around the current step: the one just done, the one
/// running, and what is queued — the prototype's set matrix.
class StepLogCard extends StatelessWidget {
  const StepLogCard({super.key, required this.state});

  final ExecutionState state;

  static const _before = 1;
  static const _after = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final steps = state.plan.steps;
    final first = (state.currentIndex - _before).clamp(0, steps.length - 1);
    final last = (state.currentIndex + _after).clamp(0, steps.length - 1);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'STEP LOG',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                '${state.stepsCompleted + state.stepsSkipped} / '
                '${state.totalSteps} THROUGH',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          for (var i = first; i <= last; i++)
            _LogRow(
              position: i + 1,
              step: steps[i],
              phase: i < state.currentIndex
                  ? _Phase.done
                  : i == state.currentIndex
                  ? _Phase.current
                  : _Phase.queued,
              isLive: state.isTimerRunning,
            ),
        ],
      ),
    );
  }
}

enum _Phase { done, current, queued }

class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.position,
    required this.step,
    required this.phase,
    required this.isLive,
  });

  final int position;
  final PlanStep step;
  final _Phase phase;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final isCurrent = phase == _Phase.current;
    final muted = phase == _Phase.queued;
    final accent = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(top: GimmySpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: GimmySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? theme.colorScheme.surfaceContainerHigh : null,
        borderRadius: GimmyRadii.cell,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (phase) {
                _Phase.done => theme.colorScheme.primaryContainer,
                _Phase.current => accent.withValues(alpha: 0.2),
                _Phase.queued => theme.colorScheme.surfaceContainerHighest,
              },
            ),
            child: phase == _Phase.done
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : Text(
                    '$position',
                    style: tokens.labelMono.copyWith(
                      color: isCurrent
                          ? accent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: GimmySpacing.sm + 4),
          Expanded(
            child: Text(
              step.name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isCurrent
                    ? accent
                    : muted
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            stepTarget(step),
            style: tokens.metricMd.copyWith(
              color: muted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: GimmySpacing.md),
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.centerRight,
              child: switch (phase) {
                _Phase.done => const GimmyBadge(label: 'Done'),
                _Phase.current => GimmyBadge(label: isLive ? 'Live' : 'Now'),
                _Phase.queued => GimmyBadge(
                  label: 'Queued',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
