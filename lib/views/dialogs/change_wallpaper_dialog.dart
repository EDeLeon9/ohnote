import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/scrollview_with_bar.dart';

class ChangeWallpaperDialog {
  const ChangeWallpaperDialog._();

  static Future<void> show({required BuildContext context}) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(13.0, 15.0, 13.0, 10.0),
          actionsPadding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 15.0),
          title: Text(
            'Select wallpaper:',
            style: Theme.of(context).textTheme.bodyLarge!,
          ),
          content: ScrollViewWithBar(
            padding: const EdgeInsets.symmetric(horizontal: 7.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240.0),
              child: Wrap(
                spacing: 10.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.center,
                children: List.generate(12, (i) => i + 1).map((e) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: AppData.settings[Settings.wallpaper]!,
                        builder: (context, wallpaper, child) {
                          return Container(
                            height: 52.0,
                            width: 52.0,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              color: wallpaper.contains('_$e.jpg') ? Theme.of(context).colorScheme.primary : null,
                            ),
                          );
                        },
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                        //Material allows to apply the border radius.
                        child: Material(
                          child: Ink.image(
                            height: 45.0,
                            width: 45.0,
                            image: AssetImage('assets/wallpapers/sliver_banner_thumb_$e.jpg'),
                            child: InkWell(
                              onTap: () {
                                AppData.settings[Settings.wallpaper]!.value = 'sliver_banner_$e.jpg';
                                AppData.updateDbSettings([Settings.wallpaper]);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }
}
