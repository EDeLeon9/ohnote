import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/settings.dart';

class ChangeWallpaperDialog {
  const ChangeWallpaperDialog._();

  static Future<void> show({required BuildContext context}) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 10.0),
          actionsPadding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 15.0),
          title: Text(
            'Select wallpaper:',
            style: Theme.of(context).textTheme.bodyLarge!,
          ),
          content: Row(
            children: [
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240.0),
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.center,
                  children: List.generate(8, (i) => i + 1).map((e) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: AppData.settings[Settings.wallpaper]!,
                          builder: (context, value, child) {
                            return Container(
                              height: 52.0,
                              width: 52.0,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                color:
                                    AppData.settings[Settings.wallpaper]!.value.contains(e.toString()) ? Theme.of(context).colorScheme.primary : null,
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
                              image: AssetImage('assets/sliver_banner_thumb_$e.jpg'),
                              child: InkWell(
                                onTap: () {
                                  AppData.settings[Settings.wallpaper]!.value = 'assets/sliver_banner_$e.jpg';
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
              const Spacer(),
            ],
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
