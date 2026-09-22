import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// The app's page transition: a short fade with a small rise.
///
/// Consistent for every pushed page, rather than the platform default, so that
/// moving between the shell and a full-screen flow reads the same everywhere —
/// and so it stays still for anyone who has asked for reduced motion.
class GimmyPageRoute<T> extends PageRouteBuilder<T> {
  GimmyPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: GimmyMotion.pageTransition,
        reverseTransitionDuration: GimmyMotion.pageTransitionReverse,
        transitionsBuilder: (context, animation, secondary, child) {
          if (GimmyMotion.isReduced(context)) return child;

          final curved = CurvedAnimation(
            parent: animation,
            curve: GimmyMotion.enter,
            reverseCurve: GimmyMotion.exit,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, GimmyMotion.enterOffset),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
