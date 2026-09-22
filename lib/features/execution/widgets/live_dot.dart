import 'package:flutter/material.dart';

/// The small pulsing dot the prototype puts beside the step counter.
///
/// It only animates while the timer is actually running. A dot that pulses
/// forever is a repaint every frame for no information.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.isLive});

  final bool isLive;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isLive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive == oldWidget.isLive) return;

    if (widget.isLive) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
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

    return SizedBox.square(
      dimension: 8,
      child: FadeTransition(
        opacity: _controller.drive(Tween(begin: 0.35, end: 1)),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
