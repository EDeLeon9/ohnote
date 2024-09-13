import 'package:flutter/material.dart';
import 'package:ohnote/tools/option_tiles.dart';
import 'package:ohnote/constants.dart' as c;

class RestoreHistoryBottomSheet {
  const RestoreHistoryBottomSheet._();

  static Future<String?> show({required BuildContext context}) {
    return showModalBottomSheet<String>(
      context: context,
      shape: c.roundedTopBorder,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SizedBox(
          height: 170.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Column(
              children: OptionTiles.build(
                context: context,
                options: {
                  'Restore text and style': Icons.restore_page,
                  'Restore just text': Icons.restore_page_outlined,
                  'Cancel': Icons.arrow_back,
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
