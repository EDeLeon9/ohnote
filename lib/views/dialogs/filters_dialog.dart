import 'package:flutter/material.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/tools/scrollview_with_bar.dart';
import 'package:ohnote/views/dialogs/filters_form.dart';
import 'package:ohnote/view_components/header_container.dart';

class FiltersDialog extends StatefulWidget {
  const FiltersDialog._(this.guiManager);

  final GuiManager guiManager;

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();

  static Future<Filters?> show({required BuildContext context, required GuiManager guiManager}) {
    return showDialog<Filters>(
      context: context,
      builder: (context) {
        return FiltersDialog._(guiManager);
      },
    );
  }
}

class _FiltersDialogState extends State<FiltersDialog> {
  final Filters _filtersResult = Filters();

  @override
  void initState() {
    widget.guiManager.updateStyleColors();
    _filtersResult.copyFrom(widget.guiManager.filters.value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      titlePadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      contentPadding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
      title: HeaderContainer(
        child: Padding(
          padding: const EdgeInsets.only(left: 30.0, top: 18.0, bottom: 8.0),
          child: Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      content: ScrollViewWithBar(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: FiltersForm(
            filtersToEdit: _filtersResult,
            availableColors: widget.guiManager.styleColors,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: null,
          child: const Text('APPLY'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, Filters()),
          child: const Text('CLEAR'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}
