import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';

/// The streak, as the compact glowing pill the prototype opens with.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final isAlive = streak > 0;

    return Semantics(
      label: streak == 1 ? 'One day streak' : '$streak day streak',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GimmySpacing.sm + 4,
          vertical: 6,
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
              color: isAlive ? tokens.intensityRest : theme.colorScheme.outline,
            ),
            const SizedBox(width: GimmySpacing.xs),
            Text(
              streak == 1 ? '1 DAY STREAK' : '$streak DAYS STREAK',
              style: tokens.labelMono.copyWith(
                color: isAlive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
