import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/label.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/filters_panel.dart';
import 'package:ohnote/views/dialogs/edit_label_dialog.dart';
import 'package:ohnote/view_components/label_tile.dart';
import 'package:ohnote/tools/single_async.dart' as a;
import 'package:ohnote/constants.dart' as c;

class LabelsPage extends StatefulWidget {
  const LabelsPage({super.key});

  @override
  State<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage> {
  final _newLabelSCK = ShowCaseKey(FirstAccess.newLabelSC);
  final _labelMoreSCK = ShowCaseKey(FirstAccess.labelMoreSC);
  final GuiManager labelsManager = GuiManager(
    sortComparison: (a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()),
    getComparisonDateTime: (note) => note.creationDateTime, //Not used.
  );

  @override
  void initState() {
    labelsManager.allList = AppData.labels
        .map((e) => Note(
              id: e.id,
              text: e.text,
              guiManager: labelsManager,
            ))
        .toList();
    labelsManager.requestFilterList();
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: [_newLabelSCK, _labelMoreSCK],
      usePostFrameCallback: true,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _didPop(didPop, context),
      child: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder(
            valueListenable: labelsManager.selectionQuantity,
            builder: (context, selectionQuantity, child) {
              return AnimatedScaleText(
                duration: c.animationDuration,
                trueText: 'Labels',
                falseText: '$selectionQuantity selected',
                condition: selectionQuantity == null,
              );
            },
          ),
          actions: [
            HeaderButtons.selectionModeButton(
              context: context,
              guiManager: labelsManager,
              button: HeaderButton(HeaderButtonDetails.selectionMode),
            ),
            _newLabelButton(),
            HeaderButtons.moreButton(
              context: context,
              button: HeaderButton(HeaderButtonDetails.more)
                ..showCaseKey = _labelMoreSCK
                ..showCaseDescription = 'To search or remove\na label tap here and\nselect the option.',
              moreButtons: [
                HeaderButton(HeaderButtonDetails.searchLabel),
                HeaderButton(HeaderButtonDetails.removeLabel),
              ],
              onSelected: (selected) {
                if (selected == HeaderButtonDetails.searchLabel) {
                  _searchLabel();
                } else if (selected == HeaderButtonDetails.removeLabel) {
                  _removeLabel();
                }
              },
            )
          ],
        ),
        body: Column(
          verticalDirection: VerticalDirection.up,
          children: [
            ValueListenableBuilder(
              valueListenable: labelsManager.displayList,
              builder: (context, displayList, child) {
                return Expanded(
                  child: displayList != null
                      ? ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            var label = displayList[index];
                            return LabelTile(
                              key: Key('label_${label.id}'),
                              label: label,
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                );
              },
            ),
            FiltersPanel(
              guiManager: labelsManager,
              useFilterChips: false,
            ),
          ],
        ),
      ),
    );
  }

  void _searchLabel() {
    labelsManager.showSearchText.value = true;
    labelsManager.searchTextFocusNode.requestFocus();
  }

  void _removeLabel() async {
    a.runFirst(() async {
      await labelsManager.startSlideAnimation(
        context: context,
        slideAnimationState: -1,
        afterAnimationStateAction: (selectedLabels) {
          List<Label> labelsToRemove = [];
          for (var label in selectedLabels) {
            labelsToRemove.add(AppData.labels.firstWhere((e) => e.id == label.id));
          }
          AppData.removeLabels(labelsToRemove);
          AppData.removeNotesFromLists(selectedLabels, labelsManager);
        },
        successMessage: 'Selected labels were removed.',
        itemsNoun: 'labels',
        confirmationDialog: () {
          return ConfirmationDialog.show(
            context: context,
            caption: 'Do you want to remove the selected labels?',
            confirmOption: 'Remove',
            confirmOptionIcon: Icons.delete_forever,
            dontShowAgainChecked: AppData.settings[Settings.hideRemoveLabelDialog]!.value == true.toString(),
            setDontShowAgain: () {
              AppData.settings[Settings.hideRemoveLabelDialog]!.value = true.toString();
              AppData.updateDbSettings([Settings.hideRemoveLabelDialog]);
            },
          );
        },
      );
    });
  }

  void _didPop(bool didPop, BuildContext context) {
    if (!didPop && !CustomShowCase.next(context)) {
      if (labelsManager.selectionQuantity.value == null && !labelsManager.showSearchText.value) {
        Navigator.pop(context);
      }
      labelsManager.selectionQuantity.value = null;
      labelsManager.showSearchText.value = false;
      labelsManager.filters.value.text = '';
      labelsManager.filters.notifyListeners();
    }
  }

  Widget _newLabelButton() {
    return CustomShowCase(
      showCaseKey: _newLabelSCK,
      description: 'To add a new label\nyou can tap here\nthen type a title\nfor the label.',
      child: Transform.rotate(
        angle: (90.0 * math.pi) / 180.0,
        child: IconButton(
          tooltip: 'New label',
          icon: const Icon(Icons.add_home_rounded),
          onPressed: () {
            a.runFirst(() async {
              labelsManager.selectionQuantity.value = null;
              var value = await EditLabelDialog.show(context: context);
              if (value != null) {
                await AppData.newLabel(value, labelsManager);
              }
            });
          },
        ),
      ),
    );
  }
}
