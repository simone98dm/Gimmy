import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/gimmy_badge.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../core/widgets/start_workout_banner.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/plan_step.dart';

/// The desktop dashboard's hero: the plan on the left with its start button,
/// and on the right the shape of the session — the prototype's strain chart,
/// drawn from the plan's own steps.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.plan,
    this.onStart,
    this.onChangePlan,
  });

  final Plan plan;
  final VoidCallback? onStart;
  final VoidCallback? onChangePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );
    final exercises = plan.exerciseNames;

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GimmyBadge(
                        label: plan.isSample ? 'Sample plan' : 'Active plan',
                      ),
                      const SizedBox(width: GimmySpacing.sm),
                      Flexible(
                        child: Text(
                          plan.isSample
                              ? 'IMPORT YOUR OWN FROM SETTINGS'
                              : 'IMPORTED ${DateFormat.MMMd().format(plan.importedAt).toUpperCase()}'
                                    ' · ${plan.sourceFilename}',
                          overflow: TextOverflow.ellipsis,
                          style: tokens.labelMono.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GimmySpacing.md),
                  Text(plan.name, style: theme.textTheme.displaySmall),
                  const SizedBox(height: GimmySpacing.xs),
                  Text(
                    exercises.isEmpty
                        ? '${plan.stepCount} steps'
                        : exercises.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: GimmySpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TelemetryPill(
                          icon: Icons.fitness_center,
                          iconColor: theme.colorScheme.primary,
                          label: 'Exercises',
                          value: '${exercises.length}',
                        ),
                      ),
                      const SizedBox(width: GimmySpacing.sm),
                      Expanded(
                        child: TelemetryPill(
                          icon: Icons.format_list_numbered,
                          iconColor: tokens.intensityRest,
                          label: 'Total steps',
                          value: '${plan.stepCount}',
                        ),
                      ),
                      const SizedBox(width: GimmySpacing.sm),
                      Expanded(
                        child: TelemetryPill(
                          icon: Icons.schedule,
                          iconColor: theme.colorScheme.primary,
                          label: 'Est. time',
                          value: DurationFormat.human(estimate),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: GimmySpacing.lg),
                  Row(
                    children: [
                      Flexible(
                        child: SizedBox(
                          width: 260,
                          child: GimmyCta(
                            label: 'START WORKOUT',
                            icon: Icons.play_arrow,
                            onPressed: onStart,
                          ),
                        ),
                      ),
                      const SizedBox(width: GimmySpacing.md),
                      TextButton.icon(
                        onPressed: onChangePlan,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Change plan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: GimmySpacing.xl),
            Expanded(flex: 5, child: IntensityProfile(plan: plan)),
          ],
        ),
      ),
    );
  }
}

/// Every step as a bar — width is its time, height its effort, colour its
/// intensity — with the minutes at each intensity underneath.
class IntensityProfile extends StatelessWidget {
  const IntensityProfile({super.key, required this.plan});

  final Plan plan;

  /// How tall each intensity's bar stands, as a share of the chart.
  static const _heights = {
    StepIntensity.active: 1.0,
    StepIntensity.warmup: 0.55,
    StepIntensity.cooldown: 0.55,
    StepIntensity.rest: 0.3,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    const perRep = AppConfig.estimatedSecondsPerRep;
    final byIntensity = plan.secondsByIntensity(secondsPerRep: perRep);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: GimmyRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SESSION INTENSITY PROFILE',
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: GimmyType.capsTracking,
            ),
          ),
          const SizedBox(height: GimmySpacing.md),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final step in plan.steps)
                    Expanded(
                      // Open steps have no time; they still get a sliver.
                      flex: step.estimatedSeconds(secondsPerRep: perRep) + 10,
                      child: FractionallySizedBox(
                        heightFactor: _heights[step.intensity],
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: intensityColor(context, step.intensity),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(GimmyRadii.sm),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: GimmySpacing.md),
          Wrap(
            spacing: GimmySpacing.md,
            runSpacing: GimmySpacing.xs,
            children: [
              for (final intensity in StepIntensity.values)
                if (byIntensity[intensity]! > 0)
                  _Legend(
                    color: intensityColor(context, intensity),
                    label:
                        '${intensity.name.toUpperCase()} '
                        '${DurationFormat.human(Duration(seconds: byIntensity[intensity]!))}',
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: GimmySpacing.xs),
        Text(
          label,
          style: GimmyTokens.of(context).labelMono
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
