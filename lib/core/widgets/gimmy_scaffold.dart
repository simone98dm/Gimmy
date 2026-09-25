import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_footer.dart';
import 'app_header.dart';
import 'app_sidebar.dart';
import 'desktop_layout.dart';

/// Page chrome for every screen: the fixed [AppHeader], the fixed [AppFooter],
/// and a body that scrolls underneath both.
///
/// Pages supply only their content. They never rebuild the header or the nav.
///
/// On a desktop browser the footer becomes an [AppSidebar] on the left and the
/// content is capped at [GimmyLayout.desktopMaxContentWidth].
class GimmyScaffold extends StatelessWidget {
  const GimmyScaffold({
    super.key,
    required this.label,
    required this.child,
    this.tab,
    this.onSelectTab,
    this.leading,
    this.sidebarItem,
    this.onSidebarSelect,
    this.sidebarFooter,
    this.extendsToBottomEdge = false,
  });

  /// Page name shown in the header.
  final String label;

  /// Which nav destination is highlighted. Null on pages that sit outside the
  /// nav bar, such as Import — those render without a footer.
  final GimmyTab? tab;

  final ValueChanged<GimmyTab>? onSelectTab;

  final Widget child;

  /// Shown at the start of the header on pushed routes.
  final Widget? leading;

  /// Highlighted in the desktop sidebar. Defaults to [tab]'s item; pushed
  /// routes set it so the sidebar still says where you are. Null with no
  /// [tab] means no sidebar.
  final SidebarItem? sidebarItem;

  /// Null leaves the sidebar showing but inert.
  final ValueChanged<SidebarItem>? onSidebarSelect;

  /// The app layer's training summary, at the foot of the sidebar.
  final Widget? sidebarFooter;

  /// Lets the page run under the home indicator instead of stopping above
  /// it, keeping the bottom inset in its `MediaQuery` so it can pad its own
  /// content. For a page with its own bottom bar (the workout), which should
  /// meet the screen edge like any system bar, not float over a strip of
  /// background.
  final bool extendsToBottomEdge;

  bool get _showFooter => tab != null && onSelectTab != null;

  @override
  Widget build(BuildContext context) {
    if (isDesktopLayout(context)) return _buildDesktop(context);

    final insets = MediaQuery.paddingOf(context);
    final bottomChrome = _showFooter
        ? GimmyLayout.footerHeight + insets.bottom
        : extendsToBottomEdge
        ? 0.0
        : insets.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: !extendsToBottomEdge,
              child: Padding(
                // Exactly the chrome, no more: the page runs full height and
                // is cut off precisely where the footer begins. Pages add
                // their own trailing spacing inside the scroll view.
                padding: EdgeInsets.only(
                  top: GimmyLayout.headerHeight + insets.top,
                  bottom: bottomChrome,
                ),
                child: child,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppHeader(label: label, leading: leading),
          ),
          if (_showFooter)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppFooter(current: tab!, onSelect: onSelectTab!),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final item =
        sidebarItem ?? (tab == null ? null : SidebarItem.fromTab(tab!));

    return Scaffold(
      body: Row(
        children: [
          if (item != null)
            AppSidebar(
              current: item,
              onSelect: onSidebarSelect,
              footer: sidebarFooter,
            ),
          Expanded(
            child: Column(
              children: [
                // The sidebar carries the brand, so the header does not repeat it.
                AppHeader(
                  label: label,
                  leading: leading,
                  showBrand: item == null,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: GimmyLayout.desktopMaxContentWidth,
                      ),
                      // Pages pad by the mobile gutter; this doubles it.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GimmySpacing.md,
                        ),
                        child: child,
                      ),
                    ),
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
