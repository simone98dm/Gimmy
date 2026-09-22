import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Shrinks its child slightly while a finger is on it.
///
/// Wraps rather than replaces whatever control is inside, using a [Listener]
/// so it never competes for the gesture: the button underneath still handles
/// its own taps, ripples and semantics, and this only watches the pointer.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// False for a disabled control — a button that does nothing should not
  /// answer to a finger.
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // The controller runs 1.0 (released) down to 0.98 (pressed), so `reverse`
    // is the press and `forward` is the release — hence the pairing.
    duration: GimmyMotion.release,
    reverseDuration: GimmyMotion.press,
    lowerBound: GimmyMotion.pressedScale,
    upperBound: 1,
    value: 1,
  );

  void _press() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  void _release() {
    if (_controller.value == 1) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (GimmyMotion.isReduced(context) || !widget.enabled) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
