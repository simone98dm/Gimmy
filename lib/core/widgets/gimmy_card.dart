import 'package:flutter/material.dart';

import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';
import 'pressable_scale.dart';

/// The design system's level-1 surface: a container with a hairline stroke and
/// a 16px radius. Every module on every page sits in one of these.
class GimmyCard extends StatelessWidget {
  const GimmyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GimmySpacing.md),
    this.isHighlighted = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Draws the accent outline and ambient glow the design system reserves for
  /// whatever is live right now.
  final bool isHighlighted;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final border = BorderSide(
      color: isHighlighted ? theme.colorScheme.primary : tokens.cardBorder,
    );
    final padded = Padding(padding: padding, child: child);

    // The shadow goes on the outside and the surface is the `Material` itself.
    // Painting the background in a child of the Material — which is what this
    // used to do — draws it straight over the ink splash, so taps registered
    // but looked like nothing happened.
    return PressableScale(
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: GimmyRadii.card,
          boxShadow: isHighlighted ? tokens.activeGlow : tokens.cardShadow,
        ),
        child: Material(
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: GimmyRadii.card,
            side: border,
          ),
          clipBehavior: Clip.antiAlias,
          child: onTap == null ? padded : InkWell(onTap: onTap, child: padded),
        ),
      ),
    );
  }
}
