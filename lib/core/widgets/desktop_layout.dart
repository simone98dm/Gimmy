import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';

/// Whether the desktop layout may be used at all. Only the web build gets it;
/// a tablet keeps the phone layout. Tests flip this to exercise it.
@visibleForTesting
bool debugDesktopLayoutEnabled = kIsWeb;

/// True on a desktop-width browser window: sidebar nav, pages in columns.
bool isDesktopLayout(BuildContext context) =>
    debugDesktopLayoutEnabled &&
    MediaQuery.sizeOf(context).width >= GimmyLayout.desktopBreakpoint;

/// Two columns side by side, top-aligned — the Stitch desktop screens' grid.
class DesktopColumns extends StatelessWidget {
  const DesktopColumns({
    super.key,
    required this.start,
    required this.end,
    this.startFlex = 1,
    this.endFlex = 1,
    this.isEqualHeight = false,
  });

  final Widget start;
  final Widget end;
  final int startFlex;
  final int endFlex;

  /// Stretches both to the taller one, for a row of cards. Only for content
  /// that is not scrollable.
  final bool isEqualHeight;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: isEqualHeight
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Expanded(flex: startFlex, child: start),
        const SizedBox(width: GimmySpacing.lg),
        Expanded(flex: endFlex, child: end),
      ],
    );
    return isEqualHeight ? IntrinsicHeight(child: row) : row;
  }
}

/// The header every Stitch desktop card opens with: an icon tile, a title over
/// a mono caption, and a status badge on the right.
class DesktopCardHeader extends StatelessWidget {
  const DesktopCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: GimmyRadii.cell,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: GimmySpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (caption != null)
                Text(
                  caption!.toUpperCase(),
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: GimmySpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
