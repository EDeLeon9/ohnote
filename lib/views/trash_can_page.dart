import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/gui_listview_builder.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/note_tile.dart';
import 'package:ohnote/views/dialogs/note_details_dialog.dart';
import 'package:ohnote/view_components/filters_panel.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/single_async.dart' as a;

class TrashCanPage extends StatefulWidget {
  const TrashCanPage({super.key, required this.trashManager});

  final GuiManager trashManager;

  @override
  State<TrashCanPage> createState() => _TrashCanPageState();
}

class _TrashCanPageState extends State<TrashCanPage> {
  final _trashMoreSCK = ShowCaseKey(FirstAccess.trashMoreSC);

  @override
  void initState() {
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: [_trashMoreSCK],
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
            valueListenable: widget.trashManager.selectionQuantity,
            builder: (context, selectionQuantity, child) {
              return AnimatedScaleText(
                duration: c.animationDuration,
                trueText: 'Trash Can',
                falseText: '$selectionQuantity selected',
                condition: selectionQuantity == null,
              );
            },
          ),
          actions: [
            HeaderButtons.selectionModeButton(
              context: context,
              guiManager: widget.trashManager,
              button: HeaderButton(HeaderButtonDetails.selectionMode),
            ),
            HeaderButtons.searchTextButton(
              guiManager: widget.trashManager,
              button: HeaderButton(HeaderButtonDetails.searchText),
            ),
            HeaderButtons.moreButton(
              context: context,
              button: HeaderButton(HeaderButtonDetails.more)
                ..showCaseKey = _trashMoreSCK
                ..showCaseDescription =
                    'Here you can filter\nnotes in trash can,\nrestore them or remove\nthem permanently. Tap\nhere to view the options.',
              moreButtons: [
                HeaderButton(HeaderButtonDetails.filters),
                HeaderButton(HeaderButtonDetails.restore),
                HeaderButton(HeaderButtonDetails.removePermanently),
              ],
              onSelected: (selected) {
                if (selected == HeaderButtonDetails.filters) {
                  HeaderButtons.filtersPressed(context: context, guiManager: widget.trashManager, updateDb: false);
                } else if (selected == HeaderButtonDetails.restore) {
                  HeaderButtons.restorePressed(context: context, guiManager: widget.trashManager);
                } else if (selected == HeaderButtonDetails.removePermanently) {
                  _removePermanentlyPressed();
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
                guiManager: widget.trashManager,
                itemBuilder: (context, index, trashNote, displayList) {
                  return NoteTile(
                    key: Key('tsh_${trashNote.id}'),
                    note: trashNote,
                    onTap: () {
                      NoteDetailsDialog.show(
                        context: context,
                        note: trashNote,
                      ).then((value) {
                        if (value == true) {
                          Future.delayed(
                            const Duration(milliseconds: 150),
                            () {
                              a.runFirst(() async {
                                await widget.trashManager.startSlideAnimation(
                                  context: context,
                                  notesToUse: [trashNote],
                                  slideAnimationState: -1,
                                  afterAnimationStateAction: (selectedNotes) {
                                    AppData.restoreNotes(selectedNotes);
                                    AppData.removeNotesFromLists(selectedNotes, widget.trashManager);
                                  },
                                  successMessage: 'Your note were restored.',
                                );
                              });
                            },
                          );
                        }
                      });
                    },
                  );
                },
              ),
              const Divider(height: 0.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 2.0),
                child: Text('Notes are kept in trash can up to 30 days.', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
              FiltersPanel(guiManager: widget.trashManager),
            ],
          ),
        ),
      ),
    );
  }

  void _removePermanentlyPressed() {
    a.runFirst(() async {
      await widget.trashManager.startSlideAnimation(
        context: context,
        slideAnimationState: 1,
        afterAnimationStateAction: (selectedNotes) {
          AppData.removeTrash(selectedNotes, widget.trashManager);
        },
        successMessage: 'Selected notes were removed permanently from trash can.',
        confirmationDialog: () {
          return ConfirmationDialog.show(
            context: context,
            caption: 'Do you want to remove permanently the selected notes from trash?',
            confirmOption: 'Remove permanently',
            confirmOptionIcon: Icons.delete_forever,
            dontShowAgainChecked: AppData.settings[Settings.hideRemovePermanentlyDialog]!.value == true.toString(),
            setDontShowAgain: () {
              AppData.settings[Settings.hideRemovePermanentlyDialog]!.value = true.toString();
              AppData.updateDbSettings([Settings.hideRemovePermanentlyDialog]);
            },
          );
        },
      );
    });
  }

  void _onPopInvoked(bool didPop, BuildContext context) {
    if (!didPop && !CustomShowCase.next(context)) {
      if (widget.trashManager.selectionQuantity.value == null && !widget.trashManager.showSearchText.value) {
        Navigator.pop(context);
      }
      widget.trashManager.selectionQuantity.value = null;
      widget.trashManager.showSearchText.value = false;
    }
  }
}
