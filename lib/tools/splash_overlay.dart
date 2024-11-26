import 'package:flutter/material.dart';

class SplashOverlay extends StatelessWidget {
  const SplashOverlay({super.key, required this.child, this.onTap, this.onLongPress});

  final Widget child;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          child: child,
        ),
        //Positioned.fill Avoids error related of infinite height.
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        ),
      ],
    );
  }
}
