import 'package:flutter/material.dart';

class ScrollViewWithBar extends StatefulWidget {
  const ScrollViewWithBar({super.key, required this.child, this.paddng = EdgeInsets.zero, this.controller});

  final Widget child;
  final EdgeInsets paddng;
  final ScrollController? controller;

  @override
  State<ScrollViewWithBar> createState() => _ScrollViewWithBarState();
}

class _ScrollViewWithBarState extends State<ScrollViewWithBar> {
  var _thumbVisibility = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(const Duration(milliseconds: 750)).whenComplete(() {
        if (mounted) {
          setState(() {
            _thumbVisibility = false;
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: _thumbVisibility,
      controller: widget.controller,
      child: SingleChildScrollView(
        child: Padding(
          padding: widget.paddng,
          child: widget.child,
        ),
      ),
    );
  }
}
