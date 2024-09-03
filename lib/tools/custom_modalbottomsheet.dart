import 'package:flutter/material.dart';
import 'package:ohnote/tools/single_async.dart' as a;

class CustomModalBottomSheet extends StatefulWidget {
  const CustomModalBottomSheet._({required this.builder, this.onInitState, this.postFrameCallback, this.validateCanPop});

  final Widget Function(ScrollController sheetScrollController) builder;
  final void Function()? onInitState;
  final void Function()? postFrameCallback;
  final bool Function()? validateCanPop;

  @override
  State<CustomModalBottomSheet> createState() => _CustomModalBottomSheetState();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(ScrollController sheetScrollController) builder,
    ShapeBorder? shape,
    void Function()? onInitState,
    void Function()? postFrameCallback,
    bool Function()? validateCanPop,
    Object? Function()? getPopValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (context) {
        return CustomModalBottomSheet._(
          onInitState: onInitState,
          postFrameCallback: postFrameCallback,
          validateCanPop: validateCanPop,
          builder: builder,
        );
      },
    );
  }
}

class _CustomModalBottomSheetState extends State<CustomModalBottomSheet> {
  @override
  void initState() {
    if (widget.postFrameCallback != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => widget.postFrameCallback!());
    }
    widget.onInitState?.call();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        //a Navigator.pop() will raise onPopInvoked with didPop forced to true, so didPop validation is required.
        if (!didPop) {
          a.runFirst(() async {
            await Future.delayed(const Duration(milliseconds: 10)); //Ensures that screenWasPressed is set correctly before continue.
            if ((widget.validateCanPop?.call() ?? true) || (context.mounted && CustomModalBottomSheetListener.of(context).screenWasPressed)) {
              Navigator.pop(context); // ignore: use_build_context_synchronously
            }
          });
        }
      },
      child: DraggableScrollableSheet(
        maxChildSize: 0.9,
        initialChildSize: 0.4,
        minChildSize: 0.3999, //having a difference between initialChildSize and minChildSize allows the sheet to be closed by dragging it down.
        expand: false,
        builder: (context, scrollController) {
          return LayoutBuilder(
            builder: (context, constraints) {
              //SingleChildScrollView enables scroll from dragging header.
              return SingleChildScrollView(
                controller: scrollController,
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(child: widget.builder(scrollController)),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Container(
                            height: 4.0,
                            width: 35.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CustomModalBottomSheetListener extends StatefulWidget {
  const CustomModalBottomSheetListener({super.key, required this.child});

  final Widget child;

  @override
  State<CustomModalBottomSheetListener> createState() => CustomModalBottomSheetListenerState();

  static CustomModalBottomSheetListenerState of(BuildContext context) => context.findAncestorStateOfType<CustomModalBottomSheetListenerState>()!;
}

class CustomModalBottomSheetListenerState extends State<CustomModalBottomSheetListener> {
  bool screenWasPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (event) async {
        screenWasPressed = true;
        await Future.delayed(const Duration(milliseconds: 20));
        screenWasPressed = false;
      },
      child: widget.child,
    );
  }
}
