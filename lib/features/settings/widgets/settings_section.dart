import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';

/// A labelled group of settings rows sharing one card.
///
/// The prototype groups by concern — appearance, workout, data — with a mono
/// green label above each card and hairline rules between the rows inside it.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: GimmySpacing.xs,
            bottom: GimmySpacing.xs,
          ),
          child: Text(
            label.toUpperCase(),
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GimmySpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: GimmyRadii.card,
            boxShadow: tokens.cardShadow,
          ),
          child: Column(
            children: [
              for (final child in children) ...[
                if (child != children.first) const _RowDivider(),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GimmySpacing.md),
      child: Container(
        height: 1,
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.6),
      ),
    );
  }
}
