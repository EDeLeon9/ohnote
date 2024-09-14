import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/data/sort_by.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/constants.dart' as c;

class SortByDialog extends StatefulWidget {
  const SortByDialog._();

  @override
  State<SortByDialog> createState() => _SortByDialogState();

  static Future<SortByChoice?> show({required BuildContext context}) {
    return showDialog<SortByChoice>(
      context: context,
      builder: (context) {
        return const SortByDialog._();
      },
    );
  }
}

class _SortByDialogState extends State<SortByDialog> {
  late SortByOrder? _order = AppData.settings[Settings.lastSortBy]!.value == SortByOrder.asc.name ? SortByOrder.asc : SortByOrder.desc;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(0, 0.0, 0, 0.0),
      insetPadding: EdgeInsets.zero,
      title: HeaderContainer(
        child: Padding(
          padding: const EdgeInsets.only(left: 30.0, top: 18.0, bottom: 8.0),
          child: Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.only(left: 12.0),
                    visualDensity: const VisualDensity(horizontal: -4.0),
                    title: Text('Ascending', style: Theme.of(context).textTheme.bodyMedium),
                    value: SortByOrder.asc,
                    groupValue: _order,
                    onChanged: (value) {
                      setState(() {
                        _order = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.only(right: 22.0),
                    visualDensity: const VisualDensity(horizontal: -4.0),
                    title: Text('Descending', style: Theme.of(context).textTheme.bodyMedium),
                    value: SortByOrder.desc,
                    groupValue: _order,
                    onChanged: (value) {
                      setState(() {
                        _order = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            c.defaultDivider,
            ...SortBy.values.map<Widget>((e) {
              return ListTile(
                title: _formatedText(e.caption),
                onTap: () => _setAndPop(context, e),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _formatedText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Text(text),
    );
  }

  void _setAndPop(BuildContext context, SortBy sortBy) {
    Navigator.pop(context, SortByChoice(sortBy, _order!));
  }
}
