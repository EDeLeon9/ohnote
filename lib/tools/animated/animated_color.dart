import 'package:flutter/material.dart';

class AnimatedColor extends StatefulWidget {
  const AnimatedColor({super.key, required this.duration, required this.color, required this.builder});

  final Duration duration;
  final Color color;
  final Widget Function(Color color) builder;

  @override
  State<AnimatedColor> createState() => _AnimatedColoState();
}

class _AnimatedColoState extends State<AnimatedColor> {
  late Color _previousColor = widget.color;

  @override
  Widget build(BuildContext context) {
    var beginColor = _previousColor;
    _previousColor = widget.color;
    return TweenAnimationBuilder(
      duration: widget.duration,
      tween: ColorTween(begin: beginColor, end: widget.color),
      builder: (context, value, child) {
        return widget.builder(value!);
      },
    );
  }
}
