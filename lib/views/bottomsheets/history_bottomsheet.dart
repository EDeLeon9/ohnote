import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/view_components/gui_listview_builder.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/views/dialogs/note_details_dialog.dart';
import 'package:ohnote/view_components/note_tile.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/views/bottomsheets/restore_history_bottomsheet.dart';
import 'package:ohnote/tools/custom_modalbottomsheet.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_toast.dart' as t;

class HistoryBottomSheet {
  HistoryBottomSheet._({required this.context, required this.historyManager});

  final BuildContext context;
  final GuiManager historyManager;
  final _historyTileSCK = ShowCaseKey(FirstAccess.historyTileSC);

  static Future<bool?> show({required BuildContext context, required GuiManager historyManager}) async {
    var historyBottomSheet = HistoryBottomSheet._(context: context, historyManager: historyManager);
    Note? historyToRestore = await CustomModalBottomSheet.show<Note>(
      context: context,
      shape: c.roundedTopBorder,
      onInitState: historyBottomSheet._onInitState,
      validateCanPop: historyBottomSheet._validateCanPop,
      builder: (sheetScrollController) {
        return Stack(
          children: [
            historyBottomSheet._body(sheetScrollController),
            historyBottomSheet._header(), //Header is required to be above the rest of the widgets to spread the shadow.
          ],
        );
      },
    );
    if (historyToRestore != null && context.mounted) {
      String? selectedOption = await RestoreHistoryBottomSheet.show(context: context);
      if (selectedOption != null && selectedOption.startsWith('Restore')) {
        AppData.restoreHistory(historyToRestore, selectedOption.endsWith('style'));
        AppData.removeNotesFromLists([historyToRestore], historyManager);
        if (context.mounted) {
          t.showCustomToast('Note restored', context);
        }
        return true;
      }
    }
    return null;
  }

  bool _validateCanPop() {
    if (CustomShowCase.next(context)) {
      return false;
    }
    if (historyManager.selectionQuantity.value != null) {
      historyManager.selectionQuantity.value = null;
      return false;
    }
    return true;
  }

  void _onInitState() {
    if (historyManager.displayList.value?.isNotEmpty == true) {
      CustomShowCase.startShowCase(
        context: context,
        showCaseKeys: [_historyTileSCK],
        usePostFrameCallback: true,
      );
    }
  }

  Widget _header() {
    return HeaderContainer(
      child: HeaderButtons(
        title: 'History',
        guiManager: historyManager,
        padding: const EdgeInsets.only(top: 25.0),
        largeMainButtons: false,
        buttons: [
          HeaderButton(HeaderButtonDetails.more),
          HeaderButton(HeaderButtonDetails.discardHistory),
        ],
      ),
    );
  }

  Widget _body(ScrollController sheetScrollController) {
    return Column(
      children: [
        const SizedBox(height: 72.0), //Space for the HeaderContainer.
        GuiListViewBuilder(
          expand: true,
          scrollController: sheetScrollController,
          guiManager: historyManager,
          itemBuilder: (context, index, history, displayList) {
            var noteTile = NoteTile(
              key: Key('hst_${history.id}'),
              note: history,
              onTap: () {
                NoteDetailsDialog.show(
                  context: context,
                  note: history,
                ).then((value) {
                  if (value == true && context.mounted) {
                    Navigator.pop(context, history);
                  }
                });
              },
            );
            return index == 0
                ? CustomShowCase(
                    showCaseKey: _historyTileSCK,
                    description: 'Tap a note history to view\nthe details. You can also\nlong-press to select it and\nperform actions.',
                    child: noteTile,
                  )
                : noteTile;
          },
        ),
      ],
    );
  }
}
