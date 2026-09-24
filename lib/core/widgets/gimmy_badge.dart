import 'package:flutter/material.dart';

import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';

/// The small mono status tag the Stitch desktop screens hang on every card
/// header: "VALIDATED", "ENCRYPTED", "LIVE".
class GimmyBadge extends StatelessWidget {
  const GimmyBadge({super.key, required this.label, this.color, this.icon});

  final String label;

  /// Defaults to the primary accent.
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GimmyRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: GimmySpacing.xs),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: GimmyTokens.of(context).labelMono.copyWith(
                color: tone,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A thin rounded progress track, the bar under every desktop stat card.
class GimmyMeter extends StatelessWidget {
  const GimmyMeter({
    super.key,
    required this.value,
    this.color,
    this.height = 4,
  });

  /// 0–1; clamped.
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(GimmyRadii.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color ?? scheme.primaryContainer),
      ),
    );
  }
}
