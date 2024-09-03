import 'package:flutter/material.dart';

class AnimatedOpacityChange extends StatefulWidget {
  const AnimatedOpacityChange({super.key, required this.duration, required this.child, this.transitionColor});

  final Duration duration;
  final Widget child;
  final Color? transitionColor;

  @override
  State<AnimatedOpacityChange> createState() => _AnimatedOpacityChangeState();
}

class _AnimatedOpacityChangeState extends State<AnimatedOpacityChange> {
  late Widget _previousChild = widget.child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: widget.transitionColor),
        AnimatedOpacity(
          duration: widget.duration ~/ 2,
          opacity: widget.child.key == _previousChild.key ? 1.0 : 0.0,
          onEnd: () {
            setState(() {
              _previousChild = widget.child;
            });
          },
          child: _previousChild,
        ),
      ],
    );
  }
}
