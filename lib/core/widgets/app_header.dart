import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';
import 'gimmy_logo.dart';

/// The fixed translucent top bar shared by every page.
///
/// Identical on all four Stitch screens apart from [label], which names the
/// current page in mono caps next to the avatar.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.label,
    this.leading,
    this.showBrand = true,
  });

  /// Page name, rendered uppercase. e.g. "Today", "Workout".
  final String label;

  /// Replaces the logo on pushed routes, where a way back matters more than
  /// the branding.
  final Widget? leading;

  /// False beside the desktop sidebar, which already shows the brand.
  final bool showBrand;

  @override
  Size get preferredSize => const Size.fromHeight(GimmyLayout.headerHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return _FrostedBar(
      child: Container(
        padding: EdgeInsets.only(top: topInset),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color: tokens.chromeShadowColor,
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SizedBox(
          height: GimmyLayout.headerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GimmySpacing.gutter,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child:
                      leading ??
                      // Beside the desktop sidebar, which carries the brand.
                      (showBrand ? const _Brand() : const SizedBox.shrink()),
                ),
                const SizedBox(width: GimmySpacing.sm),
                _PageBadge(label: label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in the design's frosted-glass effect, or in nothing at all
/// when [AppConfig.chromeBlurSigma] is zero.
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

/// The app mark and wordmark, on the left of the header.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GimmyLogo(),
        const SizedBox(width: GimmySpacing.sm),
        Flexible(
          child: Text(
            'GIMMY',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }
}

/// The page name, on the right.
///
/// Sized to its content, so when something has to give it is the wordmark on
/// the left that shortens, never the page you are looking at.
class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    // No avatar: there is no account, and a person icon suggests one.
    return Text(
      label.toUpperCase(),
      style: tokens.labelMono.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1,
      ),
    );
  }
}
