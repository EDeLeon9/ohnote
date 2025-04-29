import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/tools/scrollview_with_bar.dart';
import 'package:ohnote/view_components/label_container.dart';
import 'package:ohnote/tools/single_async.dart' as a;

class NoteLabelsDialog extends StatefulWidget {
  const NoteLabelsDialog._({required this.selectedLabelsId});

  final List<int> selectedLabelsId;

  @override
  State<NoteLabelsDialog> createState() => _NoteLabelsDialogState();

  static Future<List<int>?> show({required BuildContext context, required List<int> selectedLabelsId}) async {
    return showDialog<List<int>>(
      context: context,
      builder: (context) {
        return NoteLabelsDialog._(selectedLabelsId: selectedLabelsId);
      },
    );
  }
}

class _NoteLabelsDialogState extends State<NoteLabelsDialog> {
  final _textController = TextEditingController();
  final _labelDialogSelectSCK = ShowCaseKey(FirstAccess.labelDialogSelectSC);
  final _labelDialogNewSCK = ShowCaseKey(FirstAccess.labelDialogNewSC);
  late final Map<int, bool> _labelsMap = Map.fromEntries(AppData.labels.map((e) => MapEntry(e.id, widget.selectedLabelsId.any((id) => e.id == id))));

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
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !CustomShowCase.next(context)) {
          Navigator.pop(context, _labelsMap.entries.where((e) => e.value).map((e) => e.key).toList());
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
            description: 'Select the labels you\nwant to attach to the\nnote, then press "Done"\nto apply the labels.',
            child: ScrollViewWithBar(
              //Padding avoids shadows to be hidden
              padding: const EdgeInsets.all(3.0),
              child: Wrap(
                spacing: 15.0,
                runSpacing: 10.0,
                children: AppData.labels.map((e) {
                  var selected = _labelsMap[e.id]!;
                  return LabelContainer(
                    color: selected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
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
        actions: [
          Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 75,
                child: CustomShowCase(
                  showCaseKey: _labelDialogNewSCK,
                  description: 'You can create a new\nlabel by typing a new\nlabel name and then\ntapping the "+" button\nto add the label.',
                  child: Row(
                    children: [
                      Expanded(
                        child: LandscapeTextField(
                          controller: _textController,
                          textFieldBuilder: (controller, focusNode, readOnly) {
                            return TextField(
                              showCursor: true,
                              controller: controller,
                              focusNode: focusNode,
                              readOnly: readOnly,
                              maxLength: 25,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: 'New label',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      IconButton(
                        iconSize: 32.0,
                        style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 0.0))),
                        tooltip: 'New label',
                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          a.runFirst(() async {
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
                              if (_textController.text.isNotEmpty) {
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
                      _labelsMap.updateAll((key, value) => false);
                      setState(() {});
                    },
                    child: const Text('CLEAR ALL'),
                  ),
                  const SizedBox(width: 5.0),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('DONE'),
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
