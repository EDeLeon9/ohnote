import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animated_color.dart';
import 'package:ohnote/tools/animated/animatedscale_button.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/constants.dart' as c;

class NoteTile extends StatefulWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.enableLongPress = true});

  final Note note;
  final void Function()? onTap;
  final bool enableLongPress;

  @override
  State<NoteTile> createState() => _NoteTileState();

  static bool setNoteTileYPosition(GlobalKey globalKey, Note note) {
    if (globalKey.currentContext != null && globalKey.currentContext!.mounted) {
      var renderBox = globalKey.currentContext!.findRenderObject();
      if (renderBox is RenderBox) {
        note.tileYPosition = renderBox.localToGlobal(Offset.zero).dy;
        return true;
      }
    }
    return false;
  }
}

class _NoteTileState extends State<NoteTile> {
  final GlobalKey _noteTileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    NoteTile.setNoteTileYPosition(_noteTileKey, widget.note);
    //Material allows to set color to ListTile without removing the splash effect.
    return Material(
      key: _noteTileKey,
      //It is required to set the color in case hero is performing and size changed.
      color: widget.note.slideAnimationState == 0
          ? widget.note.color.value
          : (widget.note.slideAnimationState > 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
      child: Container(
        decoration: BoxDecoration(border: _tileBorder()),
        child: AnimatedSize(
          key: Key('asz${widget.note.id}'), //Key required to avoid wrong states when creating, deleting or dragging notes.
          duration: c.animationDuration,
          //It's being used AnimatedSize + SizedBox because height transition is from null to 0.0
          //and there will be no animation if AnimatedContainer were used.
          child: SizedBox(
            height: widget.note.slideAnimationState.abs() == 2 ? 0.0 : null,
            child: AnimatedSlide(
              key: Key('asl${widget.note.id}'), //Key required to avoid wrong states when creating, deleting or dragging notes.
              duration: c.animationDuration,
              offset: widget.note.slideAnimationState == 0
                  ? Offset.zero
                  : (widget.note.slideAnimationState > 0 ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0)),
              onEnd: () {
                if (widget.note.slideAnimationState != 0) {
                  setState(() {
                    widget.note.slideAnimationState += widget.note.slideAnimationState;
                  });
                }
              },
              child: ValueListenableBuilder(
                valueListenable: widget.note.color,
                builder: (context, color, child) {
                  return AnimatedColor(
                    duration: c.animationDuration,
                    color: color ?? Theme.of(context).colorScheme.surface,
                    builder: (animatedColor) {
                      return ListTile(
                        minVerticalPadding: 0.0,
                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        tileColor: widget.note.performingHero || AppData.themeUpdatedFromSettings ? color : animatedColor,
                        onTap: widget.onTap != null
                            ? () {
                                if (widget.note.guiManager.selectionQuantity.value != null) {
                                  _checkNote(!widget.note.isChecked.value);
                                } else {
                                  widget.onTap!();
                                }
                              }
                            : null,
                        onLongPress: widget.enableLongPress
                            ? () {
                                widget.note.isChecked.value = true;
                                HapticFeedback.vibrate();
                                widget.note.guiManager.setSelectionQuantity();
                              }
                            : null,
                        title: ValueListenableBuilder(
                          valueListenable: widget.note.guiManager.selectionQuantity,
                          builder: (context, selectionQuantity, child) {
                            return ValueListenableBuilder(
                              valueListenable: widget.note.favorite,
                              builder: (context, favorite, child) {
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
                                        if (widget.note.slideAnimationState != 0) {
                                          //SingleChildScrollView prevents overflow error message when shrinking to height 0.
                                          return SingleChildScrollView(child: _text(selectionQuantity != null, favorite));
                                        } else if (widget.note.historyDateTime == null && widget.note.trashDateTime == null) {
                                          return _hero(child: _text(selectionQuantity != null, favorite));
                                        } else {
                                          return _text(selectionQuantity != null, favorite);
                                        }
                                      },
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: _favorite(favorite),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
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
          valueListenable: widget.note.isChecked,
          builder: (context, isChecked, child) {
            return CustomCheckbox(
              key: Key('chk${widget.note.id}'), //Key required to avoid wrong states when dragging note tiles.
              checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
              checkboxColor: widget.note.foregroundColor(context),
              value: () => isChecked,
              onChanged: _checkNote,
            );
          },
        ),
      ),
    );
  }

  Widget _favorite(bool favorite) {
    var color = widget.note.foregroundColor(context, defaultColor: Theme.of(context).colorScheme.primary);
    return Transform.translate(
      offset: const Offset(6.0, 0.0),
      child: widget.note.performingHero
          ? Icon(Icons.star, color: favorite ? color : Colors.transparent)
          : AnimatedScale(
              duration: c.animationDuration,
              scale: favorite ? 1.0 : 0.0,
              curve: favorite ? AnimatedScaleButton.curve : AnimatedScaleButton.curve.flipped,
              child: Icon(Icons.star, color: color),
            ),
    );
  }

  Widget _text(bool isCheckboxVisible, bool favorite, {bool isHeroPlaceholder = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedSize(
                duration: c.animationDuration,
                child: isCheckboxVisible ? const SizedBox(width: 35.0) : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: widget.note.numberOfLines,
                builder: (context, numberOfLines, child) {
                  return ValueListenableBuilder(
                    valueListenable: widget.note.isCrossedOut,
                    builder: (context, isCrossedOut, child) {
                      var color = widget.note.performingHero || isHeroPlaceholder ? Colors.transparent : widget.note.foregroundColor(context);
                      return AnimatedPadding(
                        duration: c.animationDuration,
                        padding: favorite ? const EdgeInsets.only(right: 18.0) : EdgeInsets.zero,
                        child: Text(
                          widget.note.text,
                          maxLines: numberOfLines,
                          style: TextStyle(
                            color: color,
                            decoration: isCrossedOut ? TextDecoration.lineThrough : null,
                            decorationColor: color,
                            decorationThickness: 1.8,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Stack(
          children: [
            widget.note.trashDateTime != null
                ? Positioned.fill(
                    child: Row(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedSize(
                            duration: c.animationDuration,
                            child: isCheckboxVisible ? const SizedBox(width: 35.0) : const SizedBox.shrink(),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${widget.note.getTimeLeftInTrash().inDays + 1} days left',
                            maxLines: 1, //Required to avoid stretching tile vertically when deleting.
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: widget.note.foregroundColor(context)),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder(
                valueListenable: AppData.settings[Settings.useCreationDateTime]!,
                builder: (context, useCreationDateTime, child) {
                  String dateTimeText;
                  if (widget.note.trashDateTime != null) {
                    dateTimeText = widget.note.localFormatTrashDateTime!;
                  } else if (widget.note.historyDateTime == null && AppData.settings[Settings.useCreationDateTime]!.value == true.toString()) {
                    dateTimeText = widget.note.localFormatCreationDateTime;
                  } else {
                    dateTimeText = widget.note.localFormatModifDateTime;
                  }
                  return Text(
                    dateTimeText,
                    maxLines: 1, //Required to avoid stretching tile vertically when deleting.
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: widget.note.foregroundColor(context)),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hero({required Widget child}) {
    return Hero(
      tag: 'noteHero_${widget.note.id}',
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        return Padding(
          padding: EdgeInsets.only(top: flightDirection == HeroFlightDirection.push ? 3.0 : 0.0, right: 1.5),
          child: Text(
            widget.note.text,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: flightDirection == HeroFlightDirection.push ? null : widget.note.foregroundColor(context),
                ),
          ),
        );
      },
      placeholderBuilder: (context, heroSize, child) {
        return _text(widget.note.guiManager.selectionQuantity.value != null, widget.note.favorite.value, isHeroPlaceholder: true);
      },
      child: child,
    );
  }

  Border _tileBorder() {
    var borderSide = BorderSide(color: Theme.of(context).colorScheme.outlineVariant); //outlineVariant is used by Dividers.
    return Border(bottom: borderSide, left: widget.note.slideAnimationState != 0 ? borderSide : BorderSide.none);
  }

  void _checkNote(bool? value) {
    widget.note.isChecked.value = value == true;
    if (!widget.note.guiManager.isManualSelection && !widget.note.guiManager.displayList.value!.any((e) => e.isChecked.value)) {
      widget.note.guiManager.selectionQuantity.value = null;
    } else {
      widget.note.guiManager.setSelectionQuantity();
    }
  }
}
