import 'package:flutter/material.dart';

enum LinearFadeOutMode {
  beginning(true, false),
  ending(false, true),
  both(true, true);

  final bool _beginFlag;
  final bool _endFlag;
  const LinearFadeOutMode(this._beginFlag, this._endFlag);
}

class LinearFadeOutMask extends StatelessWidget {
  const LinearFadeOutMask({
    super.key,
    required this.begin,
    required this.end,
    required this.mode,
    required this.child,
    this.percentStops,
    this.fixedStops,
  });

  final Alignment begin;
  final Alignment end;
  final List<double>? percentStops;
  final List<double> Function(Rect bounds)? fixedStops;
  final LinearFadeOutMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(fixedStops != null || percentStops != null, 'You have to provide percentStops or fixedStops parameter for LinearFadeOutMask');
    return ShaderMask(
      shaderCallback: (bounds) {
        var stops = fixedStops != null ? fixedStops!(bounds) : percentStops!;
        return LinearGradient(
          begin: begin,
          end: end,
          colors: List.generate(stops.length, (index) {
            if ((mode._beginFlag && index == 0) || (mode._endFlag && index == stops.length - 1)) {
              return Colors.transparent;
            } else {
              return Colors.black;
            }
          }),
          stops: stops,
        ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height));
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
