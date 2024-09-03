import 'package:flutter/material.dart';
import 'package:ohnote/constants.dart' as c;

class ColoredCircle extends StatelessWidget {
  const ColoredCircle({
    super.key,
    required this.color,
    required this.diameter,
    this.selectedIconSize = 13.0,
    this.margin,
    this.onTap,
    this.isSelectedIcon,
  });

  final Color color;
  final double diameter;
  final double selectedIconSize;
  final EdgeInsetsGeometry? margin;
  final void Function()? onTap;
  final bool? isSelectedIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: diameter,
      width: diameter,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            blurRadius: 2.0,
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
            offset: const Offset(1.0, 1.0),
          ),
        ],
      ),
      child: isSelectedIcon != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(diameter * 2),
                child: AnimatedOpacity(
                  duration: c.animationDuration,
                  opacity: isSelectedIcon! ? 1.0 : 0.0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        border: Border.all(color: Theme.of(context).colorScheme.onPrimary, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 2.0,
                            color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.done,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: selectedIconSize,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
