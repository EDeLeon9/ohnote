import 'package:flutter/material.dart';

class ExplicitAnimationBuilder<T> extends StatefulWidget {
  const ExplicitAnimationBuilder({
    super.key,
    required this.begin,
    required this.end,
    required this.durationMs,
    required this.builder,
    this.curve = Curves.easeInOut,
    this.repeat = true,
    this.reverse = true,
  });

  final T begin;
  final T end;
  final Curve curve;
  final int durationMs;
  final bool repeat;
  final bool reverse;
  final Widget Function(BuildContext context, Animation<T> animation) builder;

  @override
  State<ExplicitAnimationBuilder<T>> createState() => _ExplicitAnimationBuilderState<T>();
}

class _ExplicitAnimationBuilderState<T> extends State<ExplicitAnimationBuilder<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<T> _animation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.durationMs));
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ).drive(
      Tween<T>(
        begin: widget.begin,
        end: widget.end,
      ),
    );

    if (widget.repeat) {
      _controller.repeat(reverse: widget.reverse);
    } else {
      _controller.forward();
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animation);
  }
}
