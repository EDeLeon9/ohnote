import 'package:flutter/material.dart';
import 'package:ohnote/tools/boxed_value.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/tools/option_tiles.dart';

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog._({
    required this.caption,
    required this.confirmOption,
    required this.confirmOptionIcon,
    required this.dontShowAgainValue,
  });

  final String caption;
  final String confirmOption;
  final IconData confirmOptionIcon;
  final BoxedValue<bool> dontShowAgainValue;

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();

  static Future<bool> show({
    required BuildContext context,
    required String caption,
    required String confirmOption,
    required IconData confirmOptionIcon,
    required bool dontShowAgainChecked,
    required void Function() setDontShowAgain,
  }) async {
    var confirmed = false;
    if (!dontShowAgainChecked) {
      var dontShowAgainValue = BoxedValue(dontShowAgainChecked);
      String? selected = await showDialog<String>(
        context: context,
        builder: (context) => ConfirmationDialog._(
          caption: caption,
          confirmOption: confirmOption,
          confirmOptionIcon: confirmOptionIcon,
          dontShowAgainValue: dontShowAgainValue,
        ),
      );
      if (selected != null && selected != 'Cancel') {
        confirmed = true;
        if (dontShowAgainValue.value) {
          setDontShowAgain();
        }
      }
    } else {
      confirmed = true;
    }
    return confirmed;
  }
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        widget.caption,
        style: Theme.of(context).textTheme.bodyLarge!,
      ),
      children: [
        ...OptionTiles.build(
          context: context,
          indexesToDisable: widget.dontShowAgainValue.value ? [1] : null,
          options: {
            widget.confirmOption: widget.confirmOptionIcon,
            'Cancel': Icons.arrow_back,
          },
        ),
        CustomCheckbox(
          caption: const Text('Don\'t show this message again'),
          padding: const EdgeInsets.fromLTRB(10.0, 12.0, 10.0, 5.0),
          checkboxVisualDensity: const VisualDensity(horizontal: -2.0, vertical: -2.0),
          value: () => widget.dontShowAgainValue.value,
          onChanged: (value) {
            setState(() {
              widget.dontShowAgainValue.value = value;
            });
          },
        ),
      ],
    );
  }
}
