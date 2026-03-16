import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/tools/sized_showcase.dart';
import 'package:ohnote/view_components/gui_listview_builder.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/filters_panel.dart';
import 'package:ohnote/view_components/label_container.dart';
import 'package:ohnote/views/dialogs/label_input_dialog.dart';
import 'package:ohnote/view_components/gui_item_tile.dart';
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
  final GuiManager _labelsManager = GuiManager(
    sortComparison: (a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()),
    getComparisonDateTime: (note) => note.creationDateTime, //Not used.
  );

  @override
  void initState() {
    _labelsManager.allList =
        AppData.labels
            .map(
              (e) => Note(
                id: e.id,
                text: e.text,
                guiManager: _labelsManager,
              ),
            )
            .toList();
    _labelsManager.requestUpdateDisplayList();
    SizedShowCase.startShowCase(
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
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop, context),
      child: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder(
            valueListenable: _labelsManager.selectionQuantity,
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
              guiManager: _labelsManager,
              button: HeaderButton(HeaderButtonDetails.selectionMode),
            ),
            _newLabelButton(),
            HeaderButtons.moreButton(
              context: context,
              button:
                  HeaderButton(HeaderButtonDetails.more)
                    ..showCaseKey = _labelMoreSCK
                    ..showCaseDescription = 'To search for or remove a label tap here and select the option.',
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
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            verticalDirection: VerticalDirection.up,
            children: [
              GuiListViewBuilder(
                expand: true,
                guiManager: _labelsManager,
                itemBuilder: (context, index, label, displayList) {
                  return GuiItemTile(
                    key: Key('lbl_${label.id}'),
                    item: label,
                    keysPrefix: 'lbl',
                    tilePadding: EdgeInsets.fromLTRB(16.0, index == 0 ? 10.0 : 0, 14.0, 10.0),
                    contentbuilder: (onTapPerformed, onLongPress) {
                      return LabelContainer(
                        padding: const EdgeInsets.all(7.0),
                        onTap: () {
                          if (onTapPerformed()) {
                            LabelInputDialog.show(
                              context: context,
                              text: label.text,
                            ).then((value) {
                              if (value != null) {
                                label.text = value;
                                AppData.updateLabel(AppData.labels.firstWhere((e) => e.id == label.id), value, _labelsManager);
                              }
                            });
                          }
                        },
                        onLongPress: onLongPress,
                        content: Text(
                          label.text,
                          maxLines: 1,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              FiltersPanel(
                guiManager: _labelsManager,
                useFilterChips: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _searchLabel() {
    _labelsManager.showSearchText.value = true;
    _labelsManager.searchTextFocusNode.requestFocus();
  }

  void _removeLabel() {
    a.runFirst(() async {
      await _labelsManager.startSlideAnimation(
        context: context,
        slideAnimationState: -1,
        afterAnimationStateAction: (selectedLabels) {
          AppData.removeLabels(selectedLabels.map((e) => e.id).toList());
          AppData.removeNotesFromLists(selectedLabels, _labelsManager);
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

  void _onPopInvoked(bool didPop, BuildContext context) {
    if (!didPop && !SizedShowCase.next(context)) {
      if (_labelsManager.selectionQuantity.value == null && !_labelsManager.showSearchText.value) {
        Navigator.pop(context);
      }
      _labelsManager.selectionQuantity.value = null;
      _labelsManager.showSearchText.value = false;
      _labelsManager.filters.value.text = '';
      _labelsManager.filters.notifyListeners();
    }
  }

  Widget _newLabelButton() {
    return SizedShowCase(
      showCaseKey: _newLabelSCK,
      description: 'To add a new label you can tap here and then type a title for the label.',
      child: Transform.rotate(
        angle: (90.0 * math.pi) / 180.0,
        child: IconButton(
          tooltip: 'New label',
          icon: const Icon(Icons.add_home_rounded),
          onPressed: () {
            a.runFirst(() async {
              _labelsManager.selectionQuantity.value = null;
              var value = await LabelInputDialog.show(context: context);
              if (value != null) {
                await AppData.newLabel(value, _labelsManager);
              }
            });
          },
        ),
      ),
    );
  }
}
