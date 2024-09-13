import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/view_components/label_container.dart';
import 'package:ohnote/views/dialogs/edit_label_dialog.dart';
import 'package:ohnote/constants.dart' as c;

class LabelTile extends StatefulWidget {
  const LabelTile({super.key, required this.label});

  final Note label;

  @override
  State<LabelTile> createState() => _LabelTileState();
}

class _LabelTileState extends State<LabelTile> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      key: Key('asz${widget.label.id}'), //Key required to avoid wrong states.
      duration: c.animationDuration,
      //It's being used AnimatedSize + SizedBox because height transition is from null to 0.0
      //and there will be no animation if AnimatedContainer were used.
      child: SizedBox(
        height: widget.label.slideAnimationState == -2 ? 0.0 : null,
        child: AnimatedSlide(
          key: Key('asl${widget.label.id}'), //Key required to avoid wrong states.
          duration: c.animationDuration,
          offset: widget.label.slideAnimationState == 0 ? Offset.zero : const Offset(-1.0, 0.0),
          onEnd: () {
            if (widget.label.slideAnimationState != 0) {
              setState(() {
                widget.label.slideAnimationState += widget.label.slideAnimationState;
              });
            }
          },
          child: ListTile(
            minVerticalPadding: 0.0,
            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            contentPadding: EdgeInsets.fromLTRB(16.0, widget.label.guiManager.displayList.value!.indexOf(widget.label) == 0 ? 10.0 : 0, 14.0, 10.0),
            title: ValueListenableBuilder(
              valueListenable: widget.label.guiManager.selectionQuantity,
              builder: (context, selectionQuantity, child) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _checkbox(selectionQuantity != null),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        if (widget.label.slideAnimationState != 0) {
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

  Widget _checkbox(bool isVisible) {
    return AnimatedOpacity(
      duration: c.animationDuration,
      opacity: isVisible ? 1.0 : 0.0,
      child: AbsorbPointer(
        absorbing: !isVisible,
        child: ValueListenableBuilder(
          valueListenable: widget.label.isChecked,
          builder: (context, isChecked, child) {
            return CustomCheckbox(
              key: Key('chk${widget.label.id}'), //Key required to avoid wrong states.
              checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
              value: () => isChecked,
              onChanged: _checkLabel,
            );
          },
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
          child: LabelContainer(
            padding: const EdgeInsets.all(7.0),
            onTap: () {
              if (widget.label.guiManager.selectionQuantity.value != null) {
                _checkLabel(!widget.label.isChecked.value);
              } else {
                EditLabelDialog.show(
                  context: context,
                  text: widget.label.text,
                ).then((value) {
                  if (value != null) {
                    widget.label.text = value;
                    AppData.updateLabel(AppData.labels.firstWhere((e) => e.id == widget.label.id), value, widget.label.guiManager);
                  }
                });
              }
            },
            onLongPress: () {
              widget.label.isChecked.value = true;
              HapticFeedback.vibrate();
              widget.label.guiManager.setSelectionQuantity();
            },
            content: Text(
              widget.label.text,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _checkLabel(bool? value) {
    widget.label.isChecked.value = value == true;
    if (!widget.label.guiManager.isManualSelection && !widget.label.guiManager.displayList.value!.any((e) => e.isChecked.value)) {
      widget.label.guiManager.selectionQuantity.value = null;
    } else {
      widget.label.guiManager.setSelectionQuantity();
    }
  }
}
