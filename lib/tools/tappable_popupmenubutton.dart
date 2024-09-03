import 'package:flutter/material.dart';

class TappablePopupMenuButton<T> extends StatelessWidget {
  TappablePopupMenuButton({
    super.key,
    required this.childButtonBuilder,
    required this.items,
    required this.onSelected,
    this.isVisible = true,
  });

  final GlobalKey<PopupMenuButtonState> _popupMenuButtonKey = GlobalKey();

  final bool isVisible;
  final Widget Function(void Function() showButtonMenuAction) childButtonBuilder;
  final List<PopupMenuItem<T>> items;
  final void Function(T? value) onSelected;

  @override
  Widget build(BuildContext context) {
    var child = childButtonBuilder(() => _popupMenuButtonKey.currentState!.showButtonMenu());
    return Visibility(
      visible: isVisible,
      child: PopupMenuButton<T>(
        key: _popupMenuButtonKey,
        itemBuilder: (context) => items,
        onSelected: onSelected,
        child: child,
      ),
    );
  }
}
