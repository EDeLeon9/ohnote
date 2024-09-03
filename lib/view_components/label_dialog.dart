import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';

class LabelDialog extends StatefulWidget {
  const LabelDialog({super.key, this.text});

  final String? text;

  @override
  State<LabelDialog> createState() => _LabelDialogState();

  static Future<String?> show({required BuildContext context, String? text}) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return LabelDialog(text: text);
      },
    );
  }
}

class _LabelDialogState extends State<LabelDialog> {
  late final _textController = TextEditingController()..text = widget.text ?? '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
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
            child: TextField(
              controller: _textController,
              autofocus: true,
              maxLength: 25,
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
              if (_textController.text != '') {
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
