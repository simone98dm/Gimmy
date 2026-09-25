import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';

/// The streak, as the compact glowing pill the prototype opens with.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.streak, this.best = 0});

  final int streak;

  /// The longest streak so far, offered as something to beat once the
  /// current one has lapsed.
  final int best;

  String get _label => switch ((streak, best)) {
    (1, _) => '1-DAY STREAK',
    (0, 0) => 'START A STREAK TODAY',
    (0, _) => 'BEST $best · START AGAIN TODAY',
    _ => '$streak-DAY STREAK',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final isAlive = streak > 0;

    return Semantics(
      label: _label.toLowerCase(),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GimmySpacing.ms,
          vertical: GimmySpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(GimmyRadii.pill),
          // The prototype's ember glow, but only when there is a streak to
          // be proud of.
          boxShadow: isAlive ? tokens.activeGlow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: isAlive
                  ? tokens.intensityRest
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: GimmySpacing.xs),
            Text(
              _label,
              style: tokens.labelMono.copyWith(
                color: isAlive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: GimmyType.capsTracking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
