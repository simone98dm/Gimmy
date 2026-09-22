import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The Gimmy mark: two forward-leaning strokes and a weight plate on a rounded
/// dark tile, painted directly from the Stitch logo geometry.
///
/// ponytail: the source is a 4-shape SVG. A `CustomPainter` renders it exactly
/// and keeps `flutter_svg` out of the dependency list.
class GimmyLogo extends StatelessWidget {
  const GimmyLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(
        painter: _GimmyLogoPainter(
          accent: GimmyPalette.logoAccent,
          tile: GimmyPalette.logoTile,
        ),
        isComplex: false,
      ),
    );
  }
}

class _GimmyLogoPainter extends CustomPainter {
  const _GimmyLogoPainter({required this.accent, required this.tile});

  final Color accent;
  final Color tile;

  /// The SVG is authored on a 100×100 viewBox.
  static const double _viewBox = 100;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas.scale(scale);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _viewBox, _viewBox),
        const Radius.circular(24),
      ),
      Paint()..color = tile,
    );

    final stroke = Paint()..color = accent;
    canvas.drawPath(_bar(26, 48, 58, 36), stroke);

    final ghost = Paint()..color = accent.withValues(alpha: 0.75);
    canvas.drawPath(_bar(48, 70, 80, 58), ghost);

    canvas.drawCircle(const Offset(70, 62), 7, stroke);
  }

  /// One slanted bar: `M bottomLeft,68 L topLeft,24 L topRight,24 L bottomRight,68 Z`
  Path _bar(
    double bottomLeft,
    double topLeft,
    double topRight,
    double bottomRight,
  ) {
    return Path()
      ..moveTo(bottomLeft, 68)
      ..lineTo(topLeft, 24)
      ..lineTo(topRight, 24)
      ..lineTo(bottomRight, 68)
      ..close();
  }

  @override
  bool shouldRepaint(_GimmyLogoPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.tile != tile;
}
