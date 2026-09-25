import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../data/session_comparison.dart';
import '../../history/widgets/comparison_line.dart';
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
    this.comparison,
  });

  final ExecutionState state;
  final VoidCallback onDone;

  /// Against the last run of this plan; null when there is none.
  final SessionComparison? comparison;

  static const double _blurSigma = 6;
  static const double _enterScale = 0.96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = _SummaryCard(
      state: state,
      onDone: onDone,
      comparison: comparison,
    );

    // The end of the workout is the peak of the session, so it arrives rather
    // than snaps: the workout behind pulls out of focus as the card settles.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GimmyMotion.isReduced(context)
          ? Duration.zero
          : GimmyMotion.pageTransition,
      curve: GimmyMotion.enter,
      child: card,
      builder: (context, t, card) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _blurSigma * t,
          sigmaY: _blurSigma * t,
        ),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerLowest.withValues(
            alpha: 0.8 * t,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GimmySpacing.gutter),
                child: FadeTransition(
                  opacity: AlwaysStoppedAnimation(t),
                  child: Transform.scale(
                    scale: _enterScale + (1 - _enterScale) * t,
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How the session went, which sets the tone of the summary.
///
/// Reaching the last step is not the same as doing the workout: skipping every
/// step also gets there, and should not be celebrated.
enum _Outcome {
  /// Most of the plan was actually done.
  strong,

  /// Some steps were done.
  partial,

  /// Nothing was done.
  empty;

  static const _strongShare = 0.8;

  static _Outcome of(ExecutionState state) {
    if (state.stepsCompleted == 0) return empty;
    final share = state.stepsCompleted / state.totalSteps;
    final isStrong =
        state.status == ExecutionStatus.completed && share >= _strongShare;
    return isStrong ? strong : partial;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.state,
    required this.onDone,
    required this.comparison,
  });

  final ExecutionState state;
  final VoidCallback onDone;
  final SessionComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final outcome = _Outcome.of(state);
    final noneSkipped = state.stepsSkipped == 0;
    final hasActiveTime = state.totalActiveSeconds > 0;

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
          _Badge(outcome: outcome),
          const SizedBox(height: GimmySpacing.sm),
          Text(
            switch (outcome) {
              _Outcome.strong => 'Workout done',
              _Outcome.partial => 'Session logged',
              // The session is saved and the day counts, so not "nothing".
              _Outcome.empty => 'No steps done',
            },
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            '${state.plan.name} · ${DateFormat.MMMd().add_jm().format(state.startedAt)}',
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
                  label: 'Steps done',
                  value: '${state.stepsCompleted}/${state.totalSteps}',
                  footnote: noneSkipped
                      ? 'None skipped'
                      : '${state.stepsSkipped} skipped',
                  footnoteColor: noneSkipped
                      ? tokens.intensityActive
                      : tokens.intensityRest,
                ),
              ),
              if (hasActiveTime) ...[
                const SizedBox(width: GimmySpacing.xs),
                Expanded(
                  child: _MetricTile(
                    label: 'Active time',
                    value: DurationFormat.human(
                      Duration(seconds: state.totalActiveSeconds),
                    ),
                    footnote: 'Paused time excluded',
                  ),
                ),
              ],
            ],
          ),
          if (comparison case final comparison?) ...[
            const SizedBox(height: GimmySpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: ComparisonLine(comparison: comparison),
            ),
          ],
          const SizedBox(height: GimmySpacing.md),
          GimmyCta(
            label: 'Back to Today',
            icon: Icons.arrow_forward,
            onPressed: onDone,
          ),
          // Quiet, under the way forward: for the Done that was a mis-tap.
          if (state.canUndo) ...[
            const SizedBox(height: GimmySpacing.xs),
            TextButton(
              onPressed: () =>
                  context.read<ExecutionBloc>().add(const ExecutionUndone()),
              child: const Text('Undo last step'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.outcome});

  final _Outcome outcome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStrong = outcome == _Outcome.strong;
    final fill = isStrong
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;

    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(
          switch (outcome) {
            _Outcome.strong => Icons.workspace_premium,
            _Outcome.partial => Icons.flag_outlined,
            _Outcome.empty => Icons.remove,
          },
          size: 32,
          color: isStrong ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
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
  });

  final String label;
  final String value;
  final String footnote;
  final Color? footnoteColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.sm),
      decoration: BoxDecoration(
        color: tokens.insetSurface,
        borderRadius: GimmyRadii.cell,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: GimmySpacing.xxs),
          Text(value, style: tokens.metricMd),
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
