import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collection/collection.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/tools/animated/animated_growth.dart';
import 'package:ohnote/tools/color_to_int_converter.dart';
import 'package:ohnote/tools/linear_fade_out_mask.dart';
import 'package:ohnote/view_components/colored_circle.dart';
import 'package:ohnote/views/dialogs/style_colorpicker_dialog.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_toast.dart' as t;

class StylePanelColors extends StatefulWidget {
  const StylePanelColors({super.key});

  @override
  State<StylePanelColors> createState() => _StylePanelColorsState();
}

class _StylePanelColorsState extends State<StylePanelColors> {
  static const _colorButtonDiameter = 45.0;
  Color? _dialogPickerColor;
  bool _animateColorButton = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    AppData.notesManager.stylePanelOpened.removeListener(_stylePanelOpenedChanged);
    AppData.notesManager.stylePanelOpened.addListener(_stylePanelOpenedChanged);
    super.initState();
  }

  void _stylePanelOpenedChanged() {
    //Waits for animation of showing the panel.
    Future.delayed(c.animationDuration, () {
      _scrollController.animateTo(
        AppData.notesManager.stylePanelOpened.value ? _scrollController.position.maxScrollExtent : _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.ease,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppData.notesManager.styleSelectedColor,
      builder: (context, styleSelectedColor, child) {
        return LinearFadeOutMask(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          //percentStops: const [0.01, 0.05, 0.95, 0.99],
          fixedStops: (bounds) => [
            5.0 / bounds.width,
            15.0 / bounds.width,
            (bounds.width - 15.0) / bounds.width,
            (bounds.width - 5.0) / bounds.width,
          ],
          mode: LinearFadeOutMode.both,
          child: BlockPicker(
            pickerColor: styleSelectedColor ?? Colors.transparent,
            availableColors: [
              Colors.transparent, //Clear color button.
              ...AppData.notesManager.styleColors,
              Colors.transparent, //New color button.
            ],
            layoutBuilder: (context, colors, child) {
              return SizedBox(
                height: _colorButtonDiameter,
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  mainAxisSpacing: 5.0,
                  crossAxisCount: 1,
                  children: colors.mapIndexed((index, e) {
                    if (index == 0) {
                      return _addOrClearColorButton(
                        name: 'Clear color',
                        icon: SvgPicture.asset(
                          'assets/solid_eraser.svg',
                          width: 32.0,
                          height: 32.0,
                          colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                        ),
                        onPressed: () => _saveColor(null),
                      );
                    } else if (index == colors.length - 1) {
                      return _addOrClearColorButton(
                        name: 'New color',
                        icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          _dialogPickerColor = null;
                          StyleColorPickerDialog.show(
                            context: context,
                            pickerColor: AppData.notesManager.getSelectedNotes().map((e) => e.color.value).lastOrNull ??
                                AppData.notesManager.styleColors.lastOrNull,
                            onColorChanged: (value) {
                              _dialogPickerColor = value;
                              for (var note in AppData.notesManager.getSelectedNotes()) {
                                note.color.value = value != Colors.transparent ? value : null;
                              }
                            },
                          ).whenComplete(_onClosingColorPickerDialog);
                        },
                      );
                    }
                    return child(e);
                  }).toList(),
                ),
              );
            },
            itemBuilder: (color, isCurrentColor, changeColor) {
              return _colorButton(color, changeColor);
            },
            onColorChanged: (value) {
              _saveColor(value);
            },
          ),
        );
      },
    );
  }

  Widget _colorButton(Color color, Function() changeColor) {
    return AnimatedGrowth(
      isVisible: true,
      animate: _animateColorButton,
      child: ColoredCircle(
        color: color,
        diameter: _colorButtonDiameter,
        margin: const EdgeInsets.all(6.0),
        onTap: changeColor,
        isSelectedIcon: color.toInt() == AppData.notesManager.styleSelectedColor.value?.toInt(),
      ),
    );
  }

  Widget _addOrClearColorButton({required String name, required Widget icon, required void Function() onPressed}) {
    return Center(
      child: IconButton(
        tooltip: name,
        icon: icon,
        padding: const EdgeInsets.all(3.0),
        iconSize: 35.0,
        onPressed: onPressed,
      ),
    );
  }

  void _onClosingColorPickerDialog() {
    if (_dialogPickerColor == Colors.transparent) {
      _dialogPickerColor = null;
      _saveColor(null);
      setState(() {});
    } else if (_dialogPickerColor != null) {
      _saveColor(_dialogPickerColor);
      if (!AppData.notesManager.styleColors.any((e) => e.toInt() == _dialogPickerColor!.toInt())) {
        setState(() {
          _animateColorButton = true;
          AppData.notesManager.styleColors.add(_dialogPickerColor!);
        });
        //Waits for color to be added to the list.
        Future.delayed(const Duration(milliseconds: 50), () {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 750), curve: Curves.ease);
          setState(() {
            _animateColorButton = false;
          });
        });
      }
    }
  }

  void _saveColor(Color? color) {
    var selectednotes = AppData.notesManager.getSelectedNotes();
    if (selectednotes.isNotEmpty) {
      for (var note in selectednotes) {
        note.color.value = color;
      }
      AppData.notesManager.styleSelectedColor.value = color;
      AppData.updateDbNotes(selectednotes, 'color', '${color?.toInt()}');
    } else {
      t.showCustomToast('No notes selected.', context);
    }
  }
}
