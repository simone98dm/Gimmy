import 'package:flutter/material.dart';

import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';

/// A page heading, with an optional mono eyebrow above it.
///
/// Use the eyebrow sparingly: one on every page stops it saying anything.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow case final eyebrow?) ...[
                Text(
                  eyebrow.toUpperCase(),
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: GimmySpacing.xs),
              ],
              Text(title, style: theme.textTheme.headlineLarge),
              if (subtitle != null) ...[
                const SizedBox(height: GimmySpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
