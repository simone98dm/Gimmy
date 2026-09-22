import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';

/// The countdown dial: a ring that empties as the step runs out, with the
/// remaining time in the middle.
///
/// The colour comes from [GimmyTokens.timerColorFor], so it shifts from the
/// peak accent through the pacing amber to the critical red as time runs down.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
    this.diameter = 256,
  });

  /// 1.0 when the step has just begun, 0.0 when it is spent.
  final double progress;

  final Color color;

  /// The readout in the middle — a countdown, a rep target, or a dash.
  final Widget child;

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final tokens = GimmyTokens.of(context);

    return SizedBox.square(
      dimension: diameter,
      child: CustomPaint(
        painter: _TimerRingPainter(
          progress: progress,
          color: color,
          trackColor: tokens.cardBorder,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  static const double _strokeWidth = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(_strokeWidth / 2);
    final center = rect.center;
    final radius = math.min(rect.width, rect.height) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Starts at twelve o'clock and empties clockwise.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
