import 'package:flutter/material.dart';

import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';
import 'app_footer.dart';
import 'gimmy_logo.dart';

/// The destinations in the desktop sidebar.
///
/// Unlike the bottom nav, Import is listed: on a desktop there is room for it,
/// and the Stitch desktop screens show it as a place of its own.
enum SidebarItem {
  // Same glyphs as the bottom nav: one destination, one icon.
  dashboard(icon: Icons.speed, label: 'Today'),
  active(icon: Icons.fitness_center, label: 'Workout'),
  import(icon: Icons.download, label: 'Import plan'),
  settings(icon: Icons.tune, label: 'Settings');

  const SidebarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  static SidebarItem fromTab(GimmyTab tab) => switch (tab) {
    GimmyTab.dashboard => dashboard,
    GimmyTab.active => active,
    GimmyTab.settings => settings,
  };
}

/// The fixed left navigation that replaces [AppFooter] on a desktop browser.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.current,
    this.onSelect,
    this.footer,
  });

  final SidebarItem current;

  /// Null while leaving is not allowed — first-launch import, a running
  /// workout — so the items show where you are but do not navigate.
  final ValueChanged<SidebarItem>? onSelect;

  /// Shown above the privacy note: the app layer's training summary.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      width: GimmyLayout.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: tokens.cardBorder)),
      ),
      padding: const EdgeInsets.all(GimmySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: GimmyLayout.headerHeight - GimmySpacing.md,
            child: Row(
              children: [
                const GimmyLogo(),
                const SizedBox(width: GimmySpacing.sm),
                Flexible(
                  child: Text(
                    'GIMMY',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GimmySpacing.md),
          for (final item in SidebarItem.values) ...[
            _SidebarTile(
              item: item,
              isSelected: item == current,
              onTap: onSelect == null || item == current
                  ? null
                  : () => onSelect!(item),
            ),
            const SizedBox(height: GimmySpacing.xs),
          ],
          const Spacer(),
          if (footer != null) ...[
            footer!,
            const SizedBox(height: GimmySpacing.sm),
          ],
          // The app's one privacy statement on a desktop, said once, quietly.
          Text(
            'Stored on this device only. No account, no upload.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SidebarItem item;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      // The Material carries the selected fill itself, so the splash paints
      // on top of it rather than under it.
      child: Material(
        color: isSelected
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.transparent,
        borderRadius: GimmyRadii.button,
        child: InkWell(
          onTap: onTap,
          borderRadius: GimmyRadii.button,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GimmyLayout.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.md),
              child: Row(
                children: [
                  Icon(item.icon, size: 20, color: color),
                  const SizedBox(width: GimmySpacing.md),
                  Flexible(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(color: color),
                    ),
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
