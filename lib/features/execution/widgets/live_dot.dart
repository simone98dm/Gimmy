import 'package:flutter/material.dart';

import '../../../core/theme/motion.dart';

/// The small pulsing dot the prototype puts beside the step counter.
///
/// It only animates while the timer is actually running. A dot that pulses
/// forever is a repaint every frame for no information. Under reduced motion
/// it holds still: fully lit while live, dim otherwise.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.isLive});

  final bool isLive;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GimmyMotion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive != oldWidget.isLive) _sync();
  }

  void _sync() {
    if (!widget.isLive) {
      // Back to dim: a bright, still dot reads as live while paused.
      _controller
        ..stop()
        ..value = 0;
    } else if (GimmyMotion.isReduced(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: 8,
        child: FadeTransition(
          opacity: _controller.drive(Tween(begin: 0.35, end: 1)),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
