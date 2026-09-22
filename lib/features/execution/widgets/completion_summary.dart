import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../bloc/execution_bloc.dart';

/// The completion modal, over a blurred and dimmed workout.
///
/// A modal rather than a separate page, as the prototype has it: the workout
/// you just did stays visible behind the result.
class CompletionSummary extends StatelessWidget {
  const CompletionSummary({
    super.key,
    required this.state,
    required this.onDone,
  });

  final ExecutionState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(GimmySpacing.gutter),
              child: _SummaryCard(state: state, onDone: onDone),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.onDone});

  final ExecutionState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final wasCompleted = state.status == ExecutionStatus.completed;
    final everyStepDone = state.stepsSkipped == 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.modalShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: GimmySpacing.sm),
          _Trophy(isCelebratory: wasCompleted),
          const SizedBox(height: GimmySpacing.sm),
          Text(
            wasCompleted ? 'Workout crushed! 🎉' : 'Workout ended',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            state.plan.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: GimmySpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Date & time',
                  value: DateFormat.MMMd().add_jm().format(state.startedAt),
                  footnote: _timeOfDay(state.startedAt),
                ),
              ),
              const SizedBox(width: GimmySpacing.xs),
              Expanded(
                child: _MetricTile(
                  label: 'Total time',
                  value: DurationFormat.human(
                    Duration(seconds: state.totalActiveSeconds),
                  ),
                  footnote: 'Active time',
                  isMetric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.xs),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Steps',
                  value: '${state.stepsCompleted}/${state.totalSteps}',
                  footnote: everyStepDone
                      ? '100% completed'
                      : '${state.stepsSkipped} skipped',
                  footnoteColor: everyStepDone
                      ? tokens.intensityActive
                      : tokens.intensityRest,
                  isMetric: true,
                ),
              ),
              const SizedBox(width: GimmySpacing.xs),
              Expanded(
                child: _MetricTile(
                  label: 'Outcome',
                  value: wasCompleted ? 'Complete' : 'Partial',
                  footnote: wasCompleted
                      ? 'Reached the last step'
                      : 'Ended early',
                  footnoteColor: wasCompleted
                      ? tokens.intensityActive
                      : tokens.intensityRest,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          GimmyCta(
            label: 'Return to Dashboard',
            icon: Icons.arrow_forward,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }

  static String _timeOfDay(DateTime at) {
    if (at.hour < 12) return 'Morning session';
    if (at.hour < 18) return 'Afternoon session';
    return 'Evening session';
  }
}

class _Trophy extends StatelessWidget {
  const _Trophy({required this.isCelebratory});

  final bool isCelebratory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCelebratory ? Icons.workspace_premium : Icons.flag_outlined,
          size: 32,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.footnote,
    this.footnoteColor,
    this.isMetric = false,
  });

  final String label;
  final String value;
  final String footnote;
  final Color? footnoteColor;

  /// True for figures that should read in the tabular mono face.
  final bool isMetric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.cell,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: tokens.labelMono.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: isMetric
                ? tokens.metricMd
                : theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
          Text(
            footnote,
            style: tokens.labelMono.copyWith(
              color: footnoteColor ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
