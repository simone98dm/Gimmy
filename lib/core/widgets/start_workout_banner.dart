import 'package:flutter/material.dart';

import '../../data/models/plan.dart';
import '../config/feature_flags.dart';
import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';
import '../util/duration_format.dart';
import 'gimmy_cta.dart';

/// The hero card: what the active plan is, and the button that starts it.
///
/// Laid out as the prototype's dashboard hero — a category chip and duration
/// on top, the plan name large, the exercises it contains underneath, two
/// telemetry pills, then a full-width CTA.
class StartWorkoutBanner extends StatelessWidget {
  const StartWorkoutBanner({super.key, required this.plan, this.onStart});

  final Plan plan;

  /// Null disables the button — there is no plan to run.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _PlanChip(isSample: plan.isSample)),
              const SizedBox(width: GimmySpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: GimmySpacing.xs),
                  Text(
                    DurationFormat.human(estimate),
                    style: tokens.labelMono.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          Text(plan.name, style: theme.textTheme.headlineLarge),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            _exerciseSummary(plan),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (plan.isSample) ...[
            const SizedBox(height: GimmySpacing.xs),
            Text(
              _sampleHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: GimmySpacing.md),
          Row(
            children: [
              Expanded(
                child: TelemetryPill(
                  icon: Icons.fitness_center,
                  iconColor: theme.colorScheme.primary,
                  label: 'Exercises',
                  value: '${_exerciseCount(plan)}',
                ),
              ),
              const SizedBox(width: GimmySpacing.xs),
              Expanded(
                child: TelemetryPill(
                  icon: Icons.format_list_numbered,
                  iconColor: tokens.intensityRest,
                  label: 'Total steps',
                  value: '${plan.stepCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          GimmyCta(
            label: 'START WORKOUT',
            icon: Icons.play_arrow,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }

  static const _sampleHint = 'Import your own plan from Settings.';

  static int _exerciseCount(Plan plan) => plan.exerciseNames.length;

  /// "Squat • Row left • Row right …", clipped to one line by the
  /// caller. Falls back to the warmup and cooldown when a plan is all rest.
  static String _exerciseSummary(Plan plan) {
    final names = plan.exerciseNames;
    if (names.isEmpty) {
      return plan.steps.map((s) => s.name).toSet().take(4).join(' • ');
    }
    return names.join(' • ');
  }
}

/// The prototype's category tag. Ours says what the card is, because a `.fit`
/// workout carries no category we could print honestly.
class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.isSample});

  /// The built-in sample says so, rather than passing for an import.
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.ms,
        vertical: GimmySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Text(
        isSample ? 'SAMPLE PLAN' : 'ACTIVE PLAN',
        overflow: TextOverflow.ellipsis,
        style: tokens.labelMono.copyWith(
          // Ink, not the fill: the container green fails contrast as text on
          // a light card.
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: GimmyType.capsTracking,
        ),
      ),
    );
  }
}

/// An icon and a labelled mono value on a recessed pill.
class TelemetryPill extends StatelessWidget {
  const TelemetryPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GimmySpacing.ms,
          vertical: GimmySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest.withValues(
            alpha: 0.8,
          ),
          borderRadius: GimmyRadii.card,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: GimmySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}
