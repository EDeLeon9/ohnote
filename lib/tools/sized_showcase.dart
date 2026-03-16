import 'package:flutter/material.dart';
import 'package:ohnote/tools/custom_showcase/showcaseview.dart';

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

class SizedShowCase<T> extends StatefulWidget {
  const SizedShowCase({super.key, required this.showCaseKey, required this.description, required this.child, this.overlay});

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
    var ofWidget = SizedShowCaseWidget.of<T>(context);
    assert(ofWidget._shownMap.isNotEmpty, 'SizedWidgetState._shownMap is not loaded yet');
    if (showCaseKeys.isNotEmpty) {
      List<ShowCaseKey<T>> validKeys = [];
      for (var key in showCaseKeys) {
        if (!ofWidget._shownMap[key.value]!) {
          validKeys.add(key);
        }
      }
      if (validKeys.isNotEmpty) {
        ofWidget._onFinishRequests.add(
          _OnFinishRequest<T>(() {
            if (context.mounted) {
              onFinish?.call();
            }
          }, validKeys.map((e) => e.value).toList()),
        );

        void delayedStartShowCase() {
          Future.delayed(SizedShowCase.delay, () {
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
  State<SizedShowCase> createState() => _SizedShowCaseState();
}

class _SizedShowCaseState extends State<SizedShowCase> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Showcase(
      width: 200.0,
      tooltipBorderRadius: BorderRadius.circular(5.0),
      key: widget.showCaseKey,
      description: widget.description,
      targetPadding: const EdgeInsets.all(4.0),
      textColor: theme.brightness == Brightness.dark ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
      tooltipBackgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
      movingAnimationDuration: const Duration(milliseconds: 400),
      disposeOnTap: false, //Required when using onTargetClick.
      //Tapping on the target doesn't close the Showcase so it's being used ShowCaseWidget.completed() but it doesn't animate the
      //closing, and to disable the remaining closing animations scenarios it's being used ShowCaseWidget.completed() on these other scenarios.
      onToolTipClick: () {
        ShowCaseWidget.of(context).completed(widget.showCaseKey);
      },
      onTargetClick: () {
        ShowCaseWidget.of(context).completed(widget.showCaseKey);
      },
      onBarrierClick: () {
        ShowCaseWidget.of(context).completed(widget.showCaseKey);
      },
      child:
          widget.overlay != null && _showOverlay
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

class SizedShowCaseWidget<T> extends StatefulWidget {
  const SizedShowCaseWidget({
    super.key,
    required this.shownMap,
    this.onFinish,
    required this.child,
  });

  final Widget child;
  final Map<T, bool> shownMap;
  final void Function(List<T> shownKeyValues)? onFinish;

  @override
  State<SizedShowCaseWidget<T>> createState() => SizedShowCaseWidgetState<T>();

  static SizedShowCaseWidgetState<T> of<T>(BuildContext context) => context.findAncestorStateOfType<SizedShowCaseWidgetState<T>>()!;
}

class SizedShowCaseWidgetState<T> extends State<SizedShowCaseWidget<T>> {
  final List<_OnFinishRequest<T>> _onFinishRequests = [];
  Map<T, bool> get _shownMap => widget.shownMap;

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onComplete: (index, globalKey) {
        var sizedShowCaseState = globalKey.currentContext?.findAncestorStateOfType<_SizedShowCaseState>();
        if (sizedShowCaseState?.widget.overlay != null) {
          sizedShowCaseState!.setState(() {
            sizedShowCaseState._showOverlay = false;
          });
        }
      },
      onStart: (index, globalKey) {
        var sizedShowCaseState = globalKey.currentContext?.findAncestorStateOfType<_SizedShowCaseState>();
        if (sizedShowCaseState?.widget.overlay != null) {
          sizedShowCaseState!.setState(() {
            sizedShowCaseState._showOverlay = true;
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
