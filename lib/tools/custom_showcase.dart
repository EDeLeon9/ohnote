import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowCaseKey<T> extends GlobalKey {
  // ignore: prefer_const_constructors_in_immutables , never use const for this class (as said in framework.dart)
  ShowCaseKey(this.value) : super.constructor();
  final T value;
}

class _OnFinishRequest<T> {
  _OnFinishRequest(this.request, this.shownKeyValues);

  final void Function() request;
  final List<T> shownKeyValues;
}

class CustomShowCase<T> extends StatefulWidget {
  const CustomShowCase({super.key, required this.showCaseKey, required this.description, required this.child, this.overlay});

  final ShowCaseKey<T> showCaseKey;
  final String description;
  final Widget child;
  final Widget? overlay;

  static Duration delay = const Duration(milliseconds: 300);

  static bool startShowCase<T>({
    required BuildContext context,
    required List<ShowCaseKey<T>> showCaseKeys,
    required bool usePostFrameCallback,
    void Function()? onFinish,
  }) {
    var ofWidget = CustomShowCaseWidget.of<T>(context);
    assert(ofWidget._shownMap.isNotEmpty, 'CustomShowCaseWidgetState._shownMap is not loaded yet');
    if (showCaseKeys.isNotEmpty) {
      List<ShowCaseKey<T>> validKeys = [];
      for (var key in showCaseKeys) {
        if (!ofWidget._shownMap[key.value]!) {
          validKeys.add(key);
        }
      }
      if (validKeys.isNotEmpty) {
        ofWidget._onFinishRequests.add(_OnFinishRequest<T>(() {
          if (context.mounted) {
            onFinish?.call();
          }
        }, validKeys.map((e) => e.value).toList()));

        void delayedStartShowCase() {
          Future.delayed(CustomShowCase.delay, () {
            if (context.mounted) {
              ShowCaseWidget.of(context).startShowCase(validKeys);
            }
          });
        }

        if (usePostFrameCallback) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) => delayedStartShowCase());
        } else {
          delayedStartShowCase();
        }
        return true;
      }
    }
    return false;
  }

  static bool next(BuildContext context) {
    var widget = ShowCaseWidget.of(context);
    var perform = widget.activeWidgetId != null;
    if (perform) {
      widget.next();
    }
    return perform;
  }

  @override
  State<CustomShowCase> createState() => _CustomShowCaseState();
}

class _CustomShowCaseState extends State<CustomShowCase> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Showcase(
      tooltipBorderRadius: BorderRadius.circular(5.0),
      key: widget.showCaseKey,
      description: widget.description,
      targetPadding: const EdgeInsets.all(4.0),
      textColor: theme.brightness == Brightness.dark ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
      tooltipBackgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
      movingAnimationDuration: const Duration(milliseconds: 400),
      disposeOnTap: false, //Required when using onTargetClick.
      //Tapping on the target doesn't close the Showcase so it's being used ShowCaseWidget.completed() but it doesn't animate the
      //closing, and to disable the remaining closing animations it's being used ShowCaseWidget.completed() the other two scenarios too.
      onToolTipClick: () {
        ShowCaseWidget.of(context).completed(widget.showCaseKey);
      },
      onTargetClick: () {
        ShowCaseWidget.of(context).completed(widget.showCaseKey);
      },
      onBarrierClick: () {
        ShowCaseWidget.of(context).completed(widget.showCaseKey);
      },
      child: widget.overlay != null && _showOverlay
          ? Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                widget.overlay!,
              ],
            )
          : widget.child,
    );
  }
}

class CustomShowCaseWidget<T> extends StatefulWidget {
  const CustomShowCaseWidget({
    super.key,
    required this.shownMap,
    this.onFinish,
    required this.child,
  });

  final Widget child;
  final Map<T, bool> shownMap;
  final void Function(List<T> shownKeyValues)? onFinish;

  @override
  State<CustomShowCaseWidget<T>> createState() => CustomShowCaseWidgetState<T>();

  static CustomShowCaseWidgetState<T> of<T>(BuildContext context) => context.findAncestorStateOfType<CustomShowCaseWidgetState<T>>()!;
}

class CustomShowCaseWidgetState<T> extends State<CustomShowCaseWidget<T>> {
  final List<_OnFinishRequest<T>> _onFinishRequests = [];
  Map<T, bool> get _shownMap => widget.shownMap;

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onComplete: (index, globalKey) {
        var customShowCaseState = globalKey.currentContext?.findAncestorStateOfType<_CustomShowCaseState>();
        if (customShowCaseState?.widget.overlay != null) {
          customShowCaseState!.setState(() {
            customShowCaseState._showOverlay = false;
          });
        }
      },
      onStart: (index, globalKey) {
        var customShowCaseState = globalKey.currentContext?.findAncestorStateOfType<_CustomShowCaseState>();
        if (customShowCaseState?.widget.overlay != null) {
          customShowCaseState!.setState(() {
            customShowCaseState._showOverlay = true;
          });
        }
      },
      onFinish: () {
        List<T> shownKeyValues = [];
        var onFinishRequests = List.of(_onFinishRequests);
        for (var request in onFinishRequests) {
          for (var keyValue in request.shownKeyValues) {
            _shownMap[keyValue] = true;
          }
          shownKeyValues.addAll(request.shownKeyValues);
        }
        for (var onFinishRequest in onFinishRequests) {
          _onFinishRequests.remove(onFinishRequest);
          onFinishRequest.request(); //Must be called after setting _shownMap items to true.
        }
        widget.onFinish?.call(shownKeyValues);
      },
      builder: (context) => widget.child,
    );
  }
}
