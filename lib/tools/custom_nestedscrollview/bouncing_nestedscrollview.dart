// These modifications enables the tiny bouncing effect of Material 3 (not as strong as BouncingScrollPhysics). This happens because
// the CustomScrollView used as child requires a Theme without Material 3 (useMaterial3 = false) to avoid errors.
// More at:
// https://github.com/flutter/flutter/issues/54059
// https://github.com/idootop/custom_nested_scroll_view

part of 'flutter_nestedscrollview.dart';

class BouncingNestedScrollView extends NestedScrollView {
  const BouncingNestedScrollView({
    super.key,
    super.controller,
    super.scrollDirection = Axis.vertical,
    super.reverse = false,
    //super.physics, // Not required (although the bouncing effect won't be as strong as BouncingScrollPhysics).
    required super.headerSliverBuilder,
    required super.body,
    super.dragStartBehavior = DragStartBehavior.start,
    //super.floatHeaderSlivers = false, // Must be false, floatHeaderSlivers not supported.
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scrollBehavior,
  });

  @override
  BouncingNestedScrollViewState createState() => BouncingNestedScrollViewState();
}

class BouncingNestedScrollViewState extends NestedScrollViewState {
  @override
  void initState() {
    super.initState();
    _coordinator = _BouncingNestedScrollCoordinator(
      this,
      widget.controller,
      _handleHasScrolledBodyChanged,
      widget.floatHeaderSlivers,
    );
  }
}

class _BouncingNestedScrollCoordinator extends _NestedScrollCoordinator {
  _BouncingNestedScrollCoordinator(
    super._state,
    super._parent,
    super._onHasScrolledBodyChanged,
    super._floatHeaderSlivers,
  );

  // Doesn't cause any effect, so it's being commented.
  // @override
  // _NestedScrollMetrics _getMetrics(_NestedScrollPosition innerPosition, double velocity) {
  //   return _NestedScrollMetrics(
  //     minScrollExtent: _outerPosition!.minScrollExtent,
  //     maxScrollExtent: _outerPosition!.maxScrollExtent + (innerPosition.maxScrollExtent - innerPosition.minScrollExtent),
  //     pixels: unnestOffset(innerPosition.pixels, innerPosition),
  //     viewportDimension: _outerPosition!.viewportDimension,
  //     axisDirection: _outerPosition!.axisDirection,
  //     minRange: 0,
  //     maxRange: 0,
  //     correctionOffset: 0,
  //     devicePixelRatio: _outerPosition!.devicePixelRatio,
  //   );
  // }

  // Not required since Flutter 3.13.1
  // @override
  // double unnestOffset(double value, _NestedScrollPosition source) {
  //   if (source == _outerPosition) {
  //     return clampDouble(
  //       value,
  //       _outerPosition!.minScrollExtent,
  //       _outerPosition!.maxScrollExtent,
  //     );
  //   }
  //   if (value < source.minScrollExtent) {
  //     return value - source.minScrollExtent + _outerPosition!.minScrollExtent;
  //   }
  //   // This function is not modified but this line, for improving scrolling speed when drag and droping tiles.
  //   return value - source.minScrollExtent + _outerPosition!.maxScrollExtent + (value > source.pixels ? 0.0 : -0.0);
  // }

  // Overriding this cause error when drag and dropping tiles.
  // @override
  // double unnestOffset(double value, _NestedScrollPosition source) {
  //   if (source == _outerPosition) {
  //     return value;
  //   } else {
  //     if (_outerPosition!.maxScrollExtent - _outerPosition!.pixels > precisionErrorTolerance) {
  //       print('UNNEST: ${_outerPosition!.pixels}');
  //       return _outerPosition!.pixels;
  //     }
  //     return _outerPosition!.maxScrollExtent + (value - source.minScrollExtent);
  //   }
  // }

  // Overriding this cause error when drag and dropping tiles.
  // @override
  // double nestOffset(double value, _NestedScrollPosition target) {
  //   if (target == _outerPosition) {
  //     if (value > _outerPosition!.maxScrollExtent) {
  //       return _outerPosition!.maxScrollExtent;
  //     }
  //     print('NEST IF: $value');
  //     return value;
  //   } else {
  //     if (value < _outerPosition!.maxScrollExtent) {
  //       print('NEST ELSE: ${target.minScrollExtent}');
  //       return target.minScrollExtent;
  //     }
  //     return target.minScrollExtent + (value - _outerPosition!.maxScrollExtent);
  //   }
  // }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    if (_innerPositions.isEmpty) {
      _outerPosition!.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      double outerDelta = delta;
      for (_NestedScrollPosition position in _innerPositions) {
        if (position.pixels < position.minScrollExtent) {
          double potentialOuterDelta = position.applyClampedDragUpdate(delta);
          if (potentialOuterDelta < 0.0) {
            outerDelta = math.max(outerDelta, potentialOuterDelta);
          }
        }
      }
      if (outerDelta != 0.0) {
        double innerDelta = _outerPosition!.applyClampedDragUpdate(outerDelta);
        if (innerDelta != 0.0) {
          for (_NestedScrollPosition position in _innerPositions) {
            position.applyFullDragUpdate(innerDelta);
          }
        }
      }
    } else {
      double innerDelta = delta;
      if (_floatHeaderSlivers) {
        innerDelta = _outerPosition!.applyClampedDragUpdate(delta);
      }
      if (innerDelta != 0.0) {
        double outerDelta = 0.0;
        for (_NestedScrollPosition position in _innerPositions) {
          double overscroll = position.applyClampedDragUpdate(innerDelta);
          if (overscroll > 0.0) {
            outerDelta = math.max(outerDelta, overscroll);
          }
        }
        if (outerDelta != 0.0) {
          _outerPosition!.applyFullDragUpdate(outerDelta);
        }
      }
    }
  }
}
