import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class OptionTiles {
  const OptionTiles._();

  static List<ListTile> build({required BuildContext context, required Map<String, IconData> options, List<int>? indexesToDisable}) {
    indexesToDisable ??= [];
    return options.entries.mapIndexed((index, e) {
      bool isDisabled = indexesToDisable!.contains(index);
      return ListTile(
        visualDensity: const VisualDensity(vertical: -2.0),
        leading: Icon(e.value, color: isDisabled ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary),
        title: Text(
          e.key,
          style: isDisabled ? TextStyle(color: Theme.of(context).colorScheme.outline) : null,
        ),
        onTap: isDisabled ? null : () => Navigator.pop(context, e.key),
      );
    }).toList();
  }
}
