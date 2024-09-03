import 'package:flutter/material.dart';

class SmoothMaterialPageRoute<T> extends MaterialPageRoute<T> {
  SmoothMaterialPageRoute({required super.builder});

  //CupertinoPageRoute transitionDuration is 500ms (https://api.flutter.dev/flutter/cupertino/CupertinoRouteTransitionMixin/transitionDuration.html).
  static const currentTransitionDuration = Duration(milliseconds: 500);

  @override
  Duration get transitionDuration => currentTransitionDuration;
}
