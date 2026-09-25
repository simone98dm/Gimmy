import 'package:flutter/material.dart';

import '../../data/models/plan_step.dart';
import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';
import '../util/step_target.dart';

export '../util/step_target.dart';

/// Maps a step's intensity to its design-system color.
Color intensityColor(BuildContext context, StepIntensity intensity) {
  final tokens = GimmyTokens.of(context);
  return switch (intensity) {
    StepIntensity.active => tokens.intensityActive,
    StepIntensity.rest => tokens.intensityRest,
    StepIntensity.warmup || StepIntensity.cooldown => tokens.intensityEasy,
  };
}

/// One row of a plan's step list.
///
/// Shared by the import preview and the Active page, so a step reads the same
/// way before and after it is saved.
class PlanStepTile extends StatelessWidget {
  const PlanStepTile({super.key, required this.position, required this.step});

  /// 1-based, as shown to the user.
  final int position;

  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final accent = intensityColor(context, step.intensity);

    return Semantics(
      label:
          'Step $position, ${step.name}, '
          '${step.intensity.name}, ${stepTarget(step)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GimmySpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: GimmyRadii.cell,
              ),
              child: Text(
                '$position',
                style: tokens.labelMono.copyWith(color: accent),
              ),
            ),
            const SizedBox(width: GimmySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.name, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: GimmySpacing.xxs),
                  Text(
                    step.intensity.name.toUpperCase(),
                    style: tokens.labelMono.copyWith(color: accent),
                  ),
                  if (step.notes != null) ...[
                    const SizedBox(height: GimmySpacing.xs),
                    Text(
                      step.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: GimmySpacing.sm),
            Text(
              stepTarget(step),
              style: tokens.metricMd.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
