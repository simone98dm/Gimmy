import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';

/// The pieces of the Stitch desktop settings screen the phone layout does not
/// have.

/// Title and description.
class SettingsDesktopHeader extends StatelessWidget {
  const SettingsDesktopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: theme.textTheme.displaySmall),
        const SizedBox(height: GimmySpacing.xs),
        Text(
          'Theme, workout plans, cues and the data this device keeps.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// What is stored on this device.
class LocalStorageCard extends StatelessWidget {
  const LocalStorageCard({
    super.key,
    required this.sessionCount,
    required this.hasPlan,
  });

  final int sessionCount;
  final bool hasPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: GimmyRadii.button,
      ),
      child: Row(
        children: [
          Icon(Icons.storage, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: GimmySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Local storage', style: theme.textTheme.titleMedium),
                Text(
                  '${hasPlan ? 1 : 0} plan · $sessionCount '
                  '${sessionCount == 1 ? 'session' : 'sessions'} · settings',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
