import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/note_tile.dart';
import 'package:ohnote/view_components/note_tile_proxy.dart';
import 'package:ohnote/views/main_page/main_scaffold.dart';
import 'package:ohnote/views/input_page.dart';

class MainList extends StatelessWidget {
  const MainList({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppData.notesManager.displayList,
      builder: (context, noteList, child) {
        if (noteList != null) {
          return SliverReorderableList(
            onReorder: (oldIndex, newIndex) {
              AppData.reorderNote(oldIndex, newIndex);
            },
            onReorderStart: (index) {
              var note = noteList[index];
              note.isCheckedBeforeDragging = note.isChecked.value;
              note.isChecked.value = true;
              HapticFeedback.vibrate();
              //This async code makes the animations of proxy tile to be performed correctly.
              Future.delayed(const Duration(milliseconds: 50), () => AppData.notesManager.setSelectionQuantity());
            },
            onReorderEnd: (index) {
              if (!AppData.notesManager.isManualSelection && !noteList.any((e) => e.isChecked.value)) {
                AppData.notesManager.selectionQuantity.value = null;
              } else {
                AppData.notesManager.setSelectionQuantity();
              }
              //Calling notes isChecked listeners because it was not called in NoteTileProxy dragging.
              AppData.notesManager.validateIsAllSelected();
              AppData.notesManager.setStyleSelectedValues();
            },
            proxyDecorator: (child, index, animation) {
              return NoteTileProxy(index: index, animation: animation, child: child);
            },
            itemCount: noteList.length,
            itemBuilder: (context, index) {
              var note = noteList[index];
              var noteTile = NoteTile(
                note: note,
                enableLongPress: false,
                onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => InputPage(note: note)));
                },
              );
              return ReorderableDelayedDragStartListener(
                key: Key('note_${note.id}'),
                index: index,
                child: index == 0
                    ? CustomShowCase(
                        showCaseKey: MainScaffold.of(context).noteTileSCK,
                        description: 'Tap a note to edit it. You can\nalso long-press to select it\nand perform actions, '
                            'or long-\npress to drag and drop and\nreorder notes.',
                        child: noteTile,
                      )
                    : noteTile,
              );
            },
          );
        }
        return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
