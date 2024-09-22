import 'package:flutter/material.dart';

class TappablePopupMenuButton<T> extends StatefulWidget {
  const TappablePopupMenuButton({
    super.key,
    required this.childButtonBuilder,
    required this.items,
    required this.onSelected,
    this.isVisible = true,
  });

  final bool isVisible;
  final Widget Function(void Function() showButtonMenuAction) childButtonBuilder;
  final List<PopupMenuItem<T>> items;
  final void Function(T? value) onSelected;

  @override
  State<TappablePopupMenuButton> createState() => _TappablePopupMenuButtonState<T>();
}

class _TappablePopupMenuButtonState<T> extends State<TappablePopupMenuButton<T>> {
  final GlobalKey<PopupMenuButtonState> _popupMenuButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var child = widget.childButtonBuilder(() => _popupMenuButtonKey.currentState!.showButtonMenu());
    return Visibility(
      visible: widget.isVisible,
      child: PopupMenuButton<T>(
        key: _popupMenuButtonKey,
        itemBuilder: (context) => widget.items,
        onSelected: widget.onSelected,
        child: child,
      ),
    );
  }
}
