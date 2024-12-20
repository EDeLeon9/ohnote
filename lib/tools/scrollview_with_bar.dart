import 'package:flutter/material.dart';

class ScrollViewWithBar extends StatefulWidget {
  const ScrollViewWithBar({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.scrollbarMainAxisMargin = 0.0,
    this.scrollbarCrossAxisMargin = 0.0,
    this.controller,
  });

  final Widget child;
  final EdgeInsets padding;
  final double scrollbarMainAxisMargin;
  final double scrollbarCrossAxisMargin;
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
    return Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            crossAxisMargin: widget.scrollbarCrossAxisMargin,
            mainAxisMargin: widget.scrollbarMainAxisMargin,
          ),
        ),
        child: Scrollbar(
          thumbVisibility: _thumbVisibility,
          controller: widget.controller,
          child: SingleChildScrollView(
            padding: widget.padding,
            child: widget.child,
          ),
        ));
  }
}
