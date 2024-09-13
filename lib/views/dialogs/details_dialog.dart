import 'package:flutter/material.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/colored_circle.dart';
import 'package:ohnote/view_components/header_container.dart';

class DetailsDialog extends StatefulWidget {
  const DetailsDialog._(this.note);

  final Note note;

  @override
  State<DetailsDialog> createState() => _DetailsDialogState();

  static Future<bool?> show({required BuildContext context, required Note note}) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return DetailsDialog._(note);
      },
    );
  }
}

class _DetailsDialogState extends State<DetailsDialog> {
  final _detailsDialogSCK = ShowCaseKey(FirstAccess.detailsDialogSC);

  @override
  void initState() {
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: [_detailsDialogSCK],
      usePostFrameCallback: true,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var titleTextStyle = TextStyle(fontSize: 18.0, color: theme.colorScheme.primary);
    var subtitleTextStyle = TextStyle(fontSize: 14.0, color: theme.colorScheme.primary);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !CustomShowCase.next(context)) {
          Navigator.pop(context, result);
        }
      },
      child: AlertDialog(
        clipBehavior: Clip.antiAlias,
        titlePadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.all(24.0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
        actionsPadding: const EdgeInsets.fromLTRB(15.0, 7.0, 15.0, 15.0),
        title: HeaderContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 2.0),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall, //Size of the cursor and spacing between lines.
                      children: [
                        TextSpan(text: 'Creation date\n', style: subtitleTextStyle),
                        TextSpan(text: widget.note.localFormatCreationDateTime, style: titleTextStyle),
                        TextSpan(text: '\nModification date\n', style: subtitleTextStyle),
                        TextSpan(text: widget.note.localFormatModifDateTime, style: titleTextStyle),
                      ],
                    ),
                    maxLines: 6, //Helps to size the SelectableText.
                    showCursor: true,
                  ),
                ),
                widget.note.color.value != null
                    ? ColoredCircle(color: widget.note.color.value!, diameter: 30.0, margin: const EdgeInsets.only(right: 5.0))
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Stack(
                children: [
                  CustomShowCase(
                    showCaseKey: _detailsDialogSCK,
                    description: 'You can select and copy\nthe details and even the\ndate if you need to.',
                    child: const SizedBox(
                      width: double.infinity,
                      child: Text(' '),
                    ),
                  ),
                  SelectableText(
                    widget.note.text,
                    showCursor: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(context, true),
            child: const Text('RESTORE NOTE'),
          ),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
