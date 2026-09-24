import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';

/// The destinations in the bottom navigation bar.
///
/// Importing a plan is deliberately absent: it is reached from Settings, not
/// from the nav bar, because it is a rare one-off rather than a place you go.
enum GimmyTab {
  dashboard(icon: Icons.speed, label: 'Today'),
  active(icon: Icons.fitness_center, label: 'Workout'),
  settings(icon: Icons.tune, label: 'Settings');

  const GimmyTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The fixed translucent bottom navigation shared by every page.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, required this.current, required this.onSelect});

  final GimmyTab current;
  final ValueChanged<GimmyTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = GimmyTokens.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return _FrostedBar(
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: tokens.chromeShadowColor,
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: GimmyLayout.footerHeight,
          // Equal slots, not spaceAround: the labels differ in width, so
          // spacing the gaps evenly would leave the icons off-centre.
          child: Row(
            children: [
              for (final tab in GimmyTab.values)
                Expanded(
                  child: _FooterTab(
                    tab: tab,
                    isSelected: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors the header's frosted bar. See [AppConfig.chromeBlurSigma].
class _FrostedBar extends StatelessWidget {
  const _FrostedBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.chromeBlurSigma <= 0) return child;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConfig.chromeBlurSigma,
          sigmaY: AppConfig.chromeBlurSigma,
        ),
        child: child,
      ),
    );
  }
}

class _FooterTab extends StatelessWidget {
  const _FooterTab({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final GimmyTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  /// Wide enough to thumb; the label sets the rest, and never wraps.
  static const double _minTabWidth = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      // The visible label would otherwise be read a second time, in capitals.
      excludeSemantics: true,
      // A Material *inside* the footer's background, so the splash paints on
      // top of it rather than under it.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: GimmyRadii.button,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTabWidth,
              minHeight: GimmyLayout.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: 24, color: color),
                  const SizedBox(height: GimmySpacing.xs),
                  Text(
                    tab.label.toUpperCase(),
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
