import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/note_tile.dart';
import 'package:ohnote/views/details_dialog.dart';
import 'package:ohnote/view_components/filters_panel.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/single_async.dart' as a;

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key, required this.archiveManager});

  final GuiManager archiveManager;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final _archiveMoreSCK = ShowCaseKey(FirstAccess.archiveMoreSC);

  @override
  void initState() {
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: [_archiveMoreSCK],
      usePostFrameCallback: true,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _didPop(didPop, context),
      child: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder(
            valueListenable: widget.archiveManager.selectionQuantity,
            builder: (context, selectionQuantity, child) {
              return AnimatedScaleText(
                duration: c.animationDuration,
                trueText: 'Archive',
                falseText: '$selectionQuantity selected',
                condition: selectionQuantity == null,
              );
            },
          ),
          actions: [
            HeaderButtons.selectionModeButton(
              context: context,
              guiManager: widget.archiveManager,
              button: HeaderButton(HeaderButtonDetails.selectionMode),
            ),
            HeaderButtons.searchTextButton(
              guiManager: widget.archiveManager,
              button: HeaderButton(HeaderButtonDetails.searchText),
            ),
            HeaderButtons.moreButton(
              context: context,
              button: HeaderButton(HeaderButtonDetails.more)
                ..showCaseKey = _archiveMoreSCK
                ..showCaseDescription = 'Here you can filter\narchived notes or\nunarchive them with\nrestore option. Tap here\nto view the options.',
              moreButtons: [
                HeaderButton(HeaderButtonDetails.filters),
                HeaderButton(HeaderButtonDetails.restore),
              ],
              onSelected: (selected) {
                if (selected == HeaderButtonDetails.filters) {
                  HeaderButtons.filtersPressed(context: context, guiManager: widget.archiveManager);
                } else if (selected == HeaderButtonDetails.restore) {
                  HeaderButtons.restorePressed(context: context, guiManager: widget.archiveManager);
                }
              },
            ),
          ],
        ),
        body: Column(
          verticalDirection: VerticalDirection.up,
          children: [
            ValueListenableBuilder(
              valueListenable: widget.archiveManager.displayList,
              builder: (context, archiveList, child) {
                return Expanded(
                  child: archiveList != null
                      ? ListView.builder(
                          itemCount: archiveList.length,
                          itemBuilder: (context, index) {
                            var archivedNote = archiveList[index];
                            return NoteTile(
                              key: Key('archive_${archivedNote.id}'),
                              note: archivedNote,
                              onTap: () {
                                DetailsDialog.show(
                                  context: context,
                                  note: archivedNote,
                                ).then((value) {
                                  if (value == true) {
                                    Future.delayed(
                                      const Duration(milliseconds: 150),
                                      () {
                                        a.runFirst(() async {
                                          await widget.archiveManager.startSlideAnimation(
                                            context: context,
                                            notesToUse: [archivedNote],
                                            slideAnimationState: -1,
                                            afterAnimationStateAction: (selectedNotes) {
                                              AppData.restoreNotes(selectedNotes);
                                              AppData.removeNotesFromLists(selectedNotes, widget.archiveManager);
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
                        )
                      : const Center(child: CircularProgressIndicator()),
                );
              },
            ),
            FiltersPanel(guiManager: widget.archiveManager),
          ],
        ),
      ),
    );
  }

  void _didPop(bool didPop, BuildContext context) {
    if (!didPop && !CustomShowCase.next(context)) {
      if (widget.archiveManager.selectionQuantity.value == null && !widget.archiveManager.showSearchText.value) {
        Navigator.pop(context);
      }
      widget.archiveManager.selectionQuantity.value = null;
      widget.archiveManager.showSearchText.value = false;
    }
  }
}
