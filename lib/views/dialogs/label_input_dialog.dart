import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/tools/landscape_textfield.dart';

class LabelInputDialog extends StatefulWidget {
  const LabelInputDialog._({this.text});

  final String? text;

  @override
  State<LabelInputDialog> createState() => _LabelInputDialogState();

  static Future<String?> show({required BuildContext context, String? text}) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return LabelInputDialog._(text: text);
      },
    );
  }
}

class _LabelInputDialogState extends State<LabelInputDialog> {
  late final _textController = TextEditingController()..text = widget.text ?? '';

  @override
  void initState() {
    _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24.0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 15.0),
      actionsPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 15.0),
      title: Text(
        '${widget.text == null ? 'New' : 'Edit'} Label',
        style: Theme.of(context).textTheme.titleLarge!,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: LandscapeTextField(
              controller: _textController,
              textFieldBuilder: (controller, focusNode, readOnly) {
                return TextField(
                  showCursor: true,
                  focusNode: focusNode,
                  controller: controller,
                  readOnly: readOnly,
                  autofocus: true,
                  maxLength: 25,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                );
              },
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _textController.text = _textController.text.trim();
            if (AppData.labels.any((e) => e.text.toLowerCase() == _textController.text.toLowerCase() && e.text != widget.text)) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    insetPadding: const EdgeInsets.all(70.0),
                    actionsPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 15.0),
                    content: Text('Label "${_textController.text}" already exists. Use a different label text.'),
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
                Navigator.pop(context, widget.text != _textController.text ? _textController.text : null);
              }
            }
          },
          child: const Text('DONE'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}
