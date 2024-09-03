import 'package:flutter/material.dart';

class ClipShadowPath extends StatelessWidget {
  const ClipShadowPath({super.key, required this.shadow, required this.clipper, required this.child});

  final Shadow shadow;
  final CustomClipper<Path> clipper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShadowPainter(clipper: clipper, shadow: shadow),
      child: ClipPath(clipper: clipper, child: child),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.shadow, required this.clipper});

  final Shadow shadow;
  final CustomClipper<Path> clipper;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(clipper.getClip(size).shift(shadow.offset), shadow.toPaint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
