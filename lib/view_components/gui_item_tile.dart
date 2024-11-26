import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/constants.dart' as c;

class GuiItemTile extends StatefulWidget {
  const GuiItemTile({super.key, required this.item, required this.keysPrefix, required this.contentbuilder, this.tilePadding});

  final Note item;
  final String keysPrefix;
  final Widget Function(bool Function() onTapPerformed, void Function() onLongPress) contentbuilder;
  final EdgeInsetsGeometry? tilePadding;

  @override
  State<GuiItemTile> createState() => _GuiItemTileState();

  static Widget checkbox(Note item, String keyPrefix, bool isVisible, [Color? borderColor, fillColor]) {
    return AnimatedOpacity(
      duration: c.animationDuration,
      opacity: isVisible ? 1.0 : 0.0,
      child: AbsorbPointer(
        absorbing: !isVisible,
        child: ValueListenableBuilder(
          valueListenable: item.isChecked,
          builder: (context, isChecked, child) {
            return CustomCheckbox(
              key: Key('${keyPrefix}_chk_${item.id}'), //Key required to avoid wrong states when dragging the tile.
              checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
              borderColor: borderColor,
              fillColor: fillColor,
              value: () => isChecked,
              onChanged: (value) => checkItem(item),
            );
          },
        ),
      ),
    );
  }

  static void checkItem(Note item) {
    item.isChecked.value = !item.isChecked.value;
    if (!item.guiManager.isManualSelection && !item.guiManager.displayList.value!.any((e) => e.isChecked.value)) {
      item.guiManager.selectionQuantity.value = null;
    } else {
      item.guiManager.setSelectionQuantity();
    }
  }
}

class _GuiItemTileState extends State<GuiItemTile> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      key: Key('${widget.keysPrefix}_asz_${widget.item.id}'), //Key required to avoid wrong states.
      duration: c.animationDuration,
      //It's being used AnimatedSize + SizedBox because height transition is from null to 0.0
      //and there will be no animation if AnimatedContainer were used.
      child: SizedBox(
        height: widget.item.slideAnimationState == -2 ? 0.0 : null,
        child: AnimatedSlide(
          key: Key('${widget.keysPrefix}_asl_${widget.item.id}'), //Key required to avoid wrong states.
          duration: c.animationDuration,
          offset: widget.item.slideAnimationState == 0 ? Offset.zero : const Offset(-1.0, 0.0),
          onEnd: () {
            if (widget.item.slideAnimationState != 0) {
              setState(() {
                widget.item.slideAnimationState += widget.item.slideAnimationState;
              });
            }
          },
          child: ListTile(
            minVerticalPadding: 0.0,
            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            contentPadding: widget.tilePadding ?? EdgeInsets.zero,
            title: ValueListenableBuilder(
              valueListenable: widget.item.guiManager.selectionQuantity,
              builder: (context, selectionQuantity, child) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GuiItemTile.checkbox(widget.item, widget.keysPrefix, selectionQuantity != null),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        if (widget.item.slideAnimationState != 0) {
                          //SingleChildScrollView prevents overflow error message when shrinking to height 0.
                          return SingleChildScrollView(child: _content(selectionQuantity != null));
                        } else {
                          return _content(selectionQuantity != null);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(bool isCheckboxVisible) {
    return Row(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AnimatedSize(
            duration: c.animationDuration,
            child: isCheckboxVisible ? const SizedBox(width: 35.0) : const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: widget.contentbuilder(
            () {
              if (widget.item.guiManager.selectionQuantity.value != null) {
                GuiItemTile.checkItem(widget.item);
                return false;
              }
              return true;
            },
            () {
              widget.item.isChecked.value = true;
              HapticFeedback.vibrate();
              widget.item.guiManager.setSelectionQuantity();
            },
          ),
        ),
      ],
    );
  }
}
