import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class _CustomToast extends StatefulWidget {
  const _CustomToast(this.message);

  final String message;

  static const fadeDuration = Duration(milliseconds: 300);
  static FToast? fToast;

  @override
  State<_CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<_CustomToast> {
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        setState(() {
          _isClosing = true;
        });
      },
      child: AnimatedOpacity(
        opacity: _isClosing ? 0.0 : 1.0,
        duration: _CustomToast.fadeDuration,
        onEnd: () {
          _CustomToast.fToast!.removeCustomToast();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.9),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 100.0),
            child: Text(
              widget.message,
              style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}

//Default duration of a SnackBar (https://api.flutter.dev/flutter/material/SnackBar/duration.html).
void showCustomToast(String message, BuildContext context, [int msDuration = 4000]) {
  if (_CustomToast.fToast != null) {
    _CustomToast.fToast!.removeCustomToast();
  }
  _CustomToast.fToast = FToast();
  _CustomToast.fToast!.init(context);
  _CustomToast.fToast!.showToast(
      fadeDuration: _CustomToast.fadeDuration, //Shows a bit quicker.
      toastDuration: Duration(milliseconds: msDuration),
      positionedToastBuilder: (context, child) {
        return Positioned(
          left: 0.0,
          right: 0.0,
          bottom: 32.0,
          child: child,
        );
      },
      child: _CustomToast(message));
}
