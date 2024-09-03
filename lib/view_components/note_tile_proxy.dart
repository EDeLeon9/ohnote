import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:flutter/material.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/view_components/note_tile.dart';

//Stateful instead of Stateless to make proxt tile work properly.
class NoteTileProxy extends StatefulWidget {
  const NoteTileProxy({super.key, required this.index, required this.animation, required this.child});

  final int index;
  final Animation<double> animation;
  final Widget child;

  @override
  State<NoteTileProxy> createState() => _NoteTileProxyState();
}

class _NoteTileProxyState extends State<NoteTileProxy> {
  final _globalKey = GlobalKey();
  late final Note _note = AppData.notesManager.displayList.value![widget.index];

  @override
  Widget build(BuildContext context) {
    if (NoteTile.setNoteTileYPosition(_globalKey, _note) && !_note.isCheckedBeforeDragging) {
      var previousNote = widget.index >= 1 ? AppData.notesManager.displayList.value!.elementAtOrNull(widget.index - 1) : null;
      var nextNote = AppData.notesManager.displayList.value!.elementAtOrNull(widget.index + 1);
      if (previousNote?.tileYPosition != null && _note.tileYPosition! < previousNote!.tileYPosition!) {
        //Will not raise listeners to avoid build errors. Listeners will be called after dragging is finished (in MainList class).
        _note.canRiseIsCheckedListeners = false;
        _note.isChecked.value = false;
        _note.canRiseIsCheckedListeners = true;
      } else if (nextNote?.tileYPosition != null && _note.tileYPosition! > nextNote!.tileYPosition!) {
        _note.canRiseIsCheckedListeners = false;
        _note.isChecked.value = false;
        _note.canRiseIsCheckedListeners = true;
      }
    }
    return AnimatedBuilder(
      key: _globalKey,
      animation: widget.animation,
      builder: (context, child) {
        return Material(
          elevation: lerpDouble(0.0, 3.0, widget.animation.value)!,
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              //outlineVariant is used by Dividers.
              Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)))),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
