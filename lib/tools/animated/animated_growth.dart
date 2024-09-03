import 'package:flutter/material.dart';

class AnimatedGrowth extends StatefulWidget {
  const AnimatedGrowth({
    super.key,
    required this.isVisible,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.animate = false,
  });

  final Duration duration;
  final bool isVisible;
  final bool animate;
  final Widget child;

  @override
  State<AnimatedGrowth> createState() => _AnimatedGrowthState();
}

class _AnimatedGrowthState extends State<AnimatedGrowth> {
  double scale = 1.0;

  @override
  void initState() {
    if (widget.animate) {
      scale = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {
          scale = 1.0;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: widget.duration,
      scale: widget.isVisible ? scale : 0.0,
      curve: Curves.ease,
      child: widget.child,
    );
  }
}
