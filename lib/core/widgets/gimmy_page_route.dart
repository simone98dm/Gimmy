import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// The app's page transition: a short fade with a small rise.
///
/// Consistent for every pushed page, rather than the platform default, so that
/// moving between the shell and a full-screen flow reads the same everywhere —
/// and so it stays still for anyone who has asked for reduced motion.
///
/// Except on iOS, where the platform slide is kept: it carries the left-edge
/// swipe back, which is muscle memory there. A page that must not be left that
/// way (the workout) blocks it with `PopScope`, which also stops the swipe.
class GimmyPageRoute<T> extends MaterialPageRoute<T> {
  GimmyPageRoute({required super.builder, super.settings});

  bool _isIos(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS;

  @override
  Duration get transitionDuration => GimmyMotion.pageTransition;

  @override
  Duration get reverseTransitionDuration => GimmyMotion.pageTransitionReverse;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_isIos(context)) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
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
  }
}
