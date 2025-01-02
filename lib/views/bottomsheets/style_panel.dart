import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/views/bottomsheets/style_panel_colors.dart';
import 'package:ohnote/views/main_page/main_scaffold.dart';
import 'package:ohnote/tools/custom_toast.dart' as t;

class StylePanel extends StatefulWidget {
  const StylePanel({super.key});

  @override
  State<StylePanel> createState() => _StylePanelState();
}

class _StylePanelState extends State<StylePanel> {
  int _numberOfLinesWhenChanging = 1;
  bool _changingNumberOfLines = false;

  @override
  Widget build(BuildContext context) {
    const divider = Divider(indent: 20.0, endIndent: 20.0, height: 0.0);
    //SingleChildScrollView prevents overflow message when show and hide animation is performed
    return SingleChildScrollView(
      child: Column(
        children: [
          _numberOfLinesSlider(),
          divider,
          _stylePanelColors(),
          divider,
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 7.0, right: 20.0),
            child: Stack(
              children: [
                Row(
                  children: [
                    _crossOutButton(),
                    const SizedBox(width: 15.0),
                    _useCreationDateCheck(),
                  ],
                ),
                Row(
                  children: [
                    const Spacer(),
                    const SizedBox(height: 35, child: Row(children: [VerticalDivider(width: 0.0), SizedBox(width: 5.0)])),
                    _closeButton(),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stylePanelColors() {
    return CustomShowCase(
      showCaseKey: MainScaffold.of(context).colorSCK,
      description: 'You can set a color for\nthe selected notes.',
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.0, right: 5.0),
            child: Text('Note color:'),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 7.0, right: 15.0, bottom: 7.0),
              child: StylePanelColors(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberOfLinesSlider() {
    return CustomShowCase(
      showCaseKey: MainScaffold.of(context).numberOfLinesSCK,
      description: 'Here you can set the\nnumber of lines displayed\nof the selected notes in\nthe list.',
      child: ValueListenableBuilder(
        valueListenable: AppData.notesManager.styleSelectedNumberOfLines,
        builder: (context, styleSelectedNumberOfLines, child) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 15.0, right: 20.0),
                child: Text('Number of lines to show: ${_changingNumberOfLines ? _numberOfLinesWhenChanging : styleSelectedNumberOfLines}'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 28.0, right: 10.0),
                child: ValueListenableBuilder(
                  valueListenable: AppData.notesManager.styleSelectedNumberOfLines,
                  builder: (context, styleSelectedNumberOfLines, child) {
                    return Slider(
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      value: (_changingNumberOfLines ? _numberOfLinesWhenChanging : styleSelectedNumberOfLines).toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _changingNumberOfLines = true;
                          _numberOfLinesWhenChanging = value.toInt();
                        });
                      },
                      onChangeEnd: (value) {
                        _changingNumberOfLines = false;
                        var intValue = value.toInt();
                        var selectednotes = AppData.notesManager.getSelectedNotes();
                        if (selectednotes.isNotEmpty) {
                          for (var note in selectednotes) {
                            note.numberOfLines.value = intValue;
                          }
                          AppData.notesManager.styleSelectedNumberOfLines.value = intValue;
                          AppData.updateDbNotes(selectednotes, 'number_of_lines', intValue.toString());
                        } else {
                          t.showCustomToast('No notes selected.', context);
                        }
                        AppData.notesManager.styleSelectedNumberOfLines.value = intValue;
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _crossOutButton() {
    return CustomShowCase(
      showCaseKey: MainScaffold.of(context).crossOutSCK,
      description: 'You can also toggle a\nstrikethrough style for the\nselected notes by tapping\nthis button.',
      child: ElevatedButton(
        style: Theme.of(context).elevatedButtonTheme.style!.copyWith(padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 15.0))),
        onPressed: () {
          var selectedNotes = AppData.notesManager.getSelectedNotes();
          if (selectedNotes.isNotEmpty) {
            var crossOutState = selectedNotes.any((e) => !e.isCrossedOut.value);
            var notesToUpdate = selectedNotes.where((e) => e.isCrossedOut.value == !crossOutState).toList();
            for (var note in notesToUpdate) {
              note.isCrossedOut.value = crossOutState;
            }
            AppData.updateDbNotes(notesToUpdate, 'is_crossed_out', '${crossOutState ? 1 : 0}');
          } else {
            t.showCustomToast('No notes selected.', context);
          }
        },
        child: const Text('Cross out'),
      ),
    );
  }

  Widget _useCreationDateCheck() {
    return CustomShowCase(
      showCaseKey: MainScaffold.of(context).useCreationDateTimeSCK,
      description: 'Check this option to toggle\nbetween displaying the\nmodified date and the\ncreation date.',
      child: CustomCheckbox(
        width: 145.0,
        caption: const Text('Use creation date'),
        checkboxVisualDensity: const VisualDensity(horizontal: -3.0, vertical: -3.0),
        value: () => AppData.settings[Settings.useCreationDateTime]!.value == true.toString(),
        onChanged: (value) {
          AppData.settings[Settings.useCreationDateTime]!.value = value.toString();
          AppData.updateDbSettings([Settings.useCreationDateTime]);
        },
      ),
    );
  }

  Widget _closeButton() {
    return TextButton(
      child: const Text('CLOSE'),
      onPressed: () {
        AppData.notesManager.selectionQuantity.value = null;
      },
    );
  }
}
