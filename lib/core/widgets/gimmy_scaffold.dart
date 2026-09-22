import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_footer.dart';
import 'app_header.dart';

/// Page chrome for every screen: the fixed [AppHeader], the fixed [AppFooter],
/// and a body that scrolls underneath both.
///
/// Pages supply only their content. They never rebuild the header or the nav.
class GimmyScaffold extends StatelessWidget {
  const GimmyScaffold({
    super.key,
    required this.label,
    required this.child,
    this.tab,
    this.onSelectTab,
    this.leading,
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

  bool get _showFooter => tab != null && onSelectTab != null;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final bottomChrome = _showFooter
        ? GimmyLayout.footerHeight + insets.bottom
        : insets.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
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
}
