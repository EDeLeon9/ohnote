import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/single_async.dart';
import 'package:ohnote/view_components/label_container.dart';

class LabelNoteDialog extends StatefulWidget {
  const LabelNoteDialog({super.key, required this.selectedLabelsId});

  final List<int> selectedLabelsId;

  @override
  State<LabelNoteDialog> createState() => _LabelNoteDialogState();

  static Future<List<int>?> show({required BuildContext context, required List<int> selectedLabelsId}) async {
    return showDialog<List<int>>(
      context: context,
      builder: (context) {
        return LabelNoteDialog(selectedLabelsId: selectedLabelsId);
      },
    );
  }
}

class _LabelNoteDialogState extends State<LabelNoteDialog> {
  final _textController = TextEditingController();
  final _labelDialogSelectSCK = ShowCaseKey(FirstAccess.labelDialogSelectSC);
  final _labelDialogNewSCK = ShowCaseKey(FirstAccess.labelDialogNewSC);
  late final Map<int, bool> _labelsMap = Map.fromEntries(AppData.labels.map((e) => MapEntry(e.id, widget.selectedLabelsId.any((id) => e.id == id))));
  List<int>? result;

  @override
  void initState() {
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: [_labelDialogSelectSCK, _labelDialogNewSCK],
      usePostFrameCallback: true,
    );
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && !CustomShowCase.next(context)) {
          Navigator.pop(context, result);
        } else {
          result = null;
        }
      },
      child: AlertDialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24.0),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 18.0, 24.0, 12.0),
        actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 15.0),
        title: Text(
          'Select the labels for your note',
          style: TextStyle(fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! - 2.0),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: CustomShowCase(
            showCaseKey: _labelDialogSelectSCK,
            description: 'Select the labels you want\nto attach to the note, then\npress "Done" to apply the\nlabels.',
            child: SingleChildScrollView(
              child: Padding(
                //Padding avoids shadows to be hidden
                padding: const EdgeInsets.all(3.0),
                child: Wrap(
                  spacing: 15.0,
                  runSpacing: 10.0,
                  children: AppData.labels.map((e) {
                    var selected = _labelsMap[e.id]!;
                    return LabelContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      color: selected ? null : Theme.of(context).colorScheme.surfaceVariant,
                      onTap: () {
                        setState(() {
                          _labelsMap[e.id] = !selected;
                        });
                      },
                      content: Text(
                        e.text,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                          fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 75,
                child: CustomShowCase(
                  showCaseKey: _labelDialogNewSCK,
                  description: 'You can create a new\nlabel by typing a new\nlabel name, then press\n"+" button to add the\nlabel.',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          maxLength: 25,
                          decoration: InputDecoration(
                            hintText: 'New label',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      IconButton(
                        iconSize: 32.0,
                        style: const ButtonStyle(padding: MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 0.0))),
                        tooltip: 'New label',
                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          runFirst(() async {
                            _textController.text = _textController.text.trim();
                            if (AppData.labels.any((e) => e.text.toLowerCase() == _textController.text.toLowerCase())) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    insetPadding: const EdgeInsets.all(70.0),
                                    contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 5.0),
                                    actionsPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 15.0),
                                    content: Text('Label "${_textController.text}" already exists. Use a different text for the new label.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              if (_textController.text != '') {
                                var newId = await AppData.newLabel(_textController.text, null);
                                _labelsMap.addAll({newId: true});
                                setState(() {
                                  _textController.text = '';
                                });
                              }
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      result = _labelsMap.entries.where((e) => e.value).map((e) => e.key).toList();
                      Navigator.maybePop(context, result);
                    },
                    child: const Text('DONE'),
                  ),
                  const SizedBox(width: 5.0),
                  TextButton(
                    onPressed: () {
                      _labelsMap.updateAll((key, value) => false);
                      setState(() {});
                    },
                    child: const Text('CLEAR ALL'),
                  ),
                  const SizedBox(width: 5.0),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('CANCEL'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
