import 'package:flutter/material.dart';

/// Motion tokens.
///
/// The design system asks for micro-interactions "calibrated for sweaty hands
/// and active motion": short, confirming, never in the way. Everything here is
/// under a third of a second, and nothing animates that the user did not
/// just cause.
abstract final class GimmyMotion {
  /// A control acknowledging a finger. Must be quick enough to feel like the
  /// button moved, not like the app thought about it.
  static const Duration press = Duration(milliseconds: 90);

  /// Releasing a control. Slightly slower than the press, so it settles.
  static const Duration release = Duration(milliseconds: 160);

  /// Switching between nav destinations.
  static const Duration tabChange = Duration(milliseconds: 220);

  /// Content swapping in place: the step title when the workout moves on,
  /// the completion summary arriving.
  static const Duration stateChange = Duration(milliseconds: 200);

  /// One half-cycle of the live indicator's breathing. The only motion that
  /// repeats, so slow enough to sit in peripheral vision without nagging.
  static const Duration pulse = Duration(milliseconds: 1200);

  /// Pushing or popping a page.
  static const Duration pageTransition = Duration(milliseconds: 260);

  /// Popping is faster than pushing: going back should feel like a dismissal.
  static const Duration pageTransitionReverse = Duration(milliseconds: 180);

  /// Decelerating: fast out of the gate, gentle at rest.
  static const Curve enter = Curves.easeOutCubic;

  static const Curve exit = Curves.easeInCubic;

  /// How far a control shrinks when pressed, per the design system.
  static const double pressedScale = 0.98;

  /// How far an incoming page or tab travels, as a fraction of its height.
  static const double enterOffset = 0.02;

  /// True when the platform has been asked to keep still — "Reduce Motion" on
  /// iOS, "Remove animations" on Android.
  ///
  /// Every animation here checks it. Motion sensitivity is a real
  /// accessibility need, not a preference to override.
  static bool isReduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
