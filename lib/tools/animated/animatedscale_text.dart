import 'package:flutter/material.dart';

class AnimatedScaleText extends StatelessWidget {
  const AnimatedScaleText({
    super.key,
    required this.duration,
    required this.trueText,
    required this.falseText,
    required this.condition,
    this.textStyle,
  });

  final Duration duration;
  final String trueText;
  final String falseText;
  final bool condition;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _animatedScale(trueText, condition),
        _animatedScale(falseText, !condition),
      ],
    );
  }

  Widget _animatedScale(String text, bool isVisible) {
    return AnimatedScale(
      duration: duration,
      scale: isVisible ? 1.0 : 0.75,
      curve: Curves.ease,
      child: Text(
        overflow: TextOverflow.ellipsis,
        isVisible ? text : '',
        style: textStyle,
      ),
    );
  }
}
