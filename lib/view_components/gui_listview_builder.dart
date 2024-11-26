import 'package:flutter/material.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/note.dart';

class GuiListViewBuilder extends StatelessWidget {
  const GuiListViewBuilder({super.key, required this.guiManager, required this.itemBuilder, this.expand = false, this.scrollController});

  final GuiManager guiManager;
  final Widget Function(BuildContext context, int index, Note item, List<Note> displayList) itemBuilder;
  final bool expand;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    var widget = ValueListenableBuilder(
      valueListenable: guiManager.displayList,
      builder: (context, list, child) {
        return list != null
            ? ListView.builder(
                controller: scrollController,
                itemCount: list.length,
                itemBuilder: (context, index) => itemBuilder(context, index, list[index], list),
              )
            : const Center(child: CircularProgressIndicator());
      },
    );
    if (expand) {
      return Expanded(child: widget);
    }
    return widget;
  }
}
