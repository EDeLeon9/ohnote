import 'package:flutter/material.dart';

class AnimatedScaleButton extends StatelessWidget {
  const AnimatedScaleButton({
    super.key,
    required this.duration,
    required this.tooltip,
    required this.icon,
    this.color,
    required this.onPressed,
    this.isVisible = true,
    this.isEnabled = true,
  });

  final Duration duration;
  final String tooltip;
  final IconData icon;
  final Color? color;
  final void Function() onPressed;
  final bool isVisible;
  final bool isEnabled;

  static const curve = Cubic(0.175, 0.885, 0.4, 2.25); //Can be drawn at https://cubic-bezier.com.

  @override
  Widget build(BuildContext context) {
    var buttonColor = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedScale(
      duration: duration,
      scale: isVisible ? 1.0 : 0.0,
      curve: isVisible ? curve : curve.flipped,
      child: IconButton(
        tooltip: tooltip,
        //Just horizontal -0.2 is required, but using symmetric densities avoid bluring icons.
        visualDensity: const VisualDensity(horizontal: -0.2, vertical: -0.2),
        highlightColor: buttonColor.withOpacity(0.1),
        icon: Icon(icon, color: isEnabled ? buttonColor : Theme.of(context).colorScheme.outline),
        onPressed: isEnabled
            ? () {
                if (isVisible) {
                  onPressed();
                }
              }
            : null,
      ),
    );
  }
}
