import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';

/// Heart rate, calories and effort, as a single inset strip inside the stage
/// card — three cells sharing one recessed surface, per the prototype.
///
/// All three are behind flags in [FeatureFlags] and off by default: the app has
/// no heart-rate strap, no calorie model and no way to ask for an RPE, so the
/// numbers would be invented. The component exists so that turning a flag on is
/// all it takes once there is a real source.
class MetricStrip extends StatelessWidget {
  const MetricStrip({super.key, this.bpm, this.calories, this.effort});

  final int? bpm;
  final int? calories;
  final double? effort;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.showAnyMetric) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(GimmySpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.cell,
      ),
      child: Row(
        children: [
          if (FeatureFlags.showBpm)
            Expanded(
              child: _Cell(
                label: 'BPM',
                value: bpm?.toString() ?? '––',
                icon: Icons.favorite,
                iconColor: theme.colorScheme.error,
              ),
            ),
          if (FeatureFlags.showCalories)
            Expanded(
              child: _Cell(
                label: 'Burst cal',
                value: calories == null ? '––' : '$calories kcal',
              ),
            ),
          if (FeatureFlags.showEffort)
            Expanded(
              child: _Cell(
                label: 'Effort',
                value: effort == null
                    ? '––'
                    : 'RPE ${effort!.toStringAsFixed(1)}',
                valueColor: tokens.intensityRest,
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(GimmySpacing.xs),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: tokens.labelMono.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: iconColor),
                  const SizedBox(width: 2),
                ],
                Text(
                  value,
                  style: tokens.labelMono.copyWith(
                    color: valueColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
