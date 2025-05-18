import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animated_color.dart';
import 'package:ohnote/tools/animated/animated_growth.dart';
import 'package:ohnote/tools/color_to_int_converter.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/tools/datetime_to_str_converter.dart';
import 'package:ohnote/tools/option_tiles.dart';
import 'package:ohnote/tools/single_async.dart';
import 'package:ohnote/views/about_page.dart';
import 'package:ohnote/views/dialogs/change_wallpaper_dialog.dart';
import 'package:ohnote/view_components/colored_circle.dart';
import 'package:ohnote/views/dialogs/style_colorpicker_dialog.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_toast.dart' as t;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Color? _defaultColor;
  Color? _previousDefaultColor;
  bool _animateColorCircle = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Future.delayed(const Duration(milliseconds: 50), () {
        setState(() {
          _animateColorCircle = true;
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            _theme(),
            c.defaultDivider,
            _wallpaper(),
            c.defaultDivider,
            _maxHistory(),
            c.defaultDivider,
            _useCreationDateCheck(),
            c.defaultDivider,
            _defaultNoteColor(),
            c.defaultDivider,
            _defaultNumberOfLines(),
            c.defaultDivider,
            _resetSettingsToDefault(context),
            c.defaultDivider,
            _resetDontShowAgain(context),
            c.defaultDivider,
            _restartStartupHelp(context),
            // c.defaultDivider,
            // _sendCrashes(),
            c.defaultDivider,
            _about(),
          ],
        ),
      ),
    );
  }

  Widget _theme() {
    return ValueListenableBuilder(
      valueListenable: AppData.settings[Settings.theme]!,
      builder: (context, theme, child) {
        return ListTile(
          title: Text('Theme', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          subtitle: Text(theme),
          onTap: () {
            showDialog<String>(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  children: OptionTiles.build(
                    context: context,
                    options: {
                      AppThemeBrightness.systemDefault.caption: Icons.brightness_6,
                      AppThemeBrightness.light.caption: Icons.light_mode,
                      AppThemeBrightness.dark.caption: Icons.dark_mode,
                    },
                  ),
                );
              },
            ).then((value) {
              if (value != null && value != AppData.settings[Settings.theme]!.value) {
                AppData.settings[Settings.theme]!.value = value;
                AppData.themeUpdatedFromSettings = true;
                AppData.updateDbSettings([Settings.theme]);
              }
            });
          },
        );
      },
    );
  }

  Widget _wallpaper() {
    return ListTile(
      title: Text('Change main list wallpaper', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      subtitle: const Text('You can also long-press the wallpaper in the main list to change it'),
      onTap: () {
        ChangeWallpaperDialog.show(context: context);
      },
    );
  }

  Widget _defaultNoteColor() {
    return ValueListenableBuilder(
      valueListenable: AppData.settings[Settings.defaultColor]!,
      builder: (context, defaultColorStr, child) {
        _previousDefaultColor = _defaultColor;
        _defaultColor = defaultColorStr != null.toString() ? Color(int.parse(defaultColorStr)) : null;
        return ListTile(
          title: Text('Default color in new notes', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          trailing: AnimatedGrowth(
            animate: _animateColorCircle,
            isVisible: _defaultColor != null,
            child:
                _previousDefaultColor != null && _defaultColor != null
                    ? AnimatedColor(
                      duration: c.animationDuration,
                      color: _defaultColor!,
                      builder: (color) => ColoredCircle(color: color, diameter: 25.0),
                    )
                    : (_defaultColor != null || _previousDefaultColor != null
                        ? ColoredCircle(color: _defaultColor ?? _previousDefaultColor!, diameter: 25.0)
                        : const SizedBox.shrink()),
          ),
          onTap: () {
            StyleColorPickerDialog.show(
              context: context,
              pickerColor: _defaultColor,
              onColorChanged: (value) {
                AppData.settings[Settings.defaultColor]!.value = value != Colors.transparent ? value.toInt().toString() : null.toString();
              },
            ).whenComplete(() {
              AppData.updateDbSettings([Settings.defaultColor]);
            });
          },
        );
      },
    );
  }

  Widget _defaultNumberOfLines() {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text('Default number of lines in new notes', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          subtitle: ValueListenableBuilder(
            valueListenable: AppData.settings[Settings.defaultNumberOfLines]!,
            builder: (context, defaultNumberOfLines, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(defaultNumberOfLines)),
                  Slider(
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    value: double.parse(defaultNumberOfLines),
                    onChanged: (value) {
                      AppData.settings[Settings.defaultNumberOfLines]!.value = value.toInt().toString();
                    },
                    onChangeEnd: (value) {
                      AppData.updateDbSettings([Settings.defaultNumberOfLines]);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _maxHistory() {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text('Max number of history per note', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          subtitle: ValueListenableBuilder(
            valueListenable: AppData.settings[Settings.maxHistory]!,
            builder: (context, maxHistory, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(maxHistory)),
                  Slider(
                    min: 0.0,
                    max: 10.0,
                    divisions: 10,
                    value: double.parse(maxHistory),
                    onChanged: (value) {
                      AppData.settings[Settings.maxHistory]!.value = value.toInt().toString();
                    },
                    onChangeEnd: (value) {
                      AppData.updateDbSettings([Settings.maxHistory]);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _useCreationDateCheck() {
    void check() {
      String value = AppData.settings[Settings.useCreationDateTime]!.value == true.toString() ? false.toString() : true.toString();
      AppData.settings[Settings.useCreationDateTime]!.value = value;
      AppData.updateDbSettings([Settings.useCreationDateTime]);
    }

    return ListTile(
      title: Text('Show creation date in main list', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      trailing: ValueListenableBuilder(
        valueListenable: AppData.settings[Settings.useCreationDateTime]!,
        builder: (context, useCreationDateTime, child) {
          return CustomCheckbox(
            checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            value: () => useCreationDateTime == true.toString(),
            onChanged: (value) => check(),
          );
        },
      ),
      onTap: check,
    );
  }

  Widget _resetSettingsToDefault(BuildContext context) {
    return ListTile(
      title: Text('Reset above settings to default', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      onTap: () {
        showDialog<String>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text('Do you want to reset these settings to the default values?', style: Theme.of(context).textTheme.bodyLarge!),
              children: OptionTiles.build(context: context, options: {'Reset': Icons.restart_alt, 'Cancel': Icons.arrow_back}),
            );
          },
        ).then((value) {
          if (value == 'Reset') {
            AppData.settings[Settings.theme]!.value = AppThemeBrightness.systemDefault.caption;
            AppData.settings[Settings.wallpaper]!.value = c.defaultWallpaper;
            AppData.settings[Settings.defaultColor]!.value = null.toString();
            AppData.settings[Settings.defaultNumberOfLines]!.value = '1';
            AppData.settings[Settings.maxHistory]!.value = '5';
            AppData.settings[Settings.useCreationDateTime]!.value = false.toString();
            AppData.updateDbSettings([
              Settings.theme,
              Settings.defaultColor,
              Settings.defaultNumberOfLines,
              Settings.maxHistory,
              Settings.useCreationDateTime,
            ]);
            if (context.mounted) {
              t.showCustomToast('Settings were reset to default values.', context);
            }
          }
        });
      },
    );
  }

  Widget _restartStartupHelp(BuildContext context) {
    return ListTile(
      title: Text('Restart startup help', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      onTap: () {
        showDialog<String>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text('Do you want to reset the startup help?', style: Theme.of(context).textTheme.bodyLarge!),
              children: OptionTiles.build(context: context, options: {'Restart': Icons.restart_alt, 'Cancel': Icons.arrow_back}),
            );
          },
        ).then((value) {
          if (value == 'Restart') {
            AppData.firstAccesses.forEach((key, value) {
              AppData.firstAccesses[key] = false;
            });
            AppData.updateDbShownFirstAccesses(AppData.firstAccesses.entries.map((e) => e.key).where((e) => e.name.endsWith('SC')).toList(), false);
            if (context.mounted) {
              t.showCustomToast('Startup help was restarted.', context);
            }
          }
        });
      },
    );
  }

  Widget _sendCrashes() {
    return ListTile(
      title: Text('Send app crashes to support', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      onTap: () {
        t.showCustomToast('Comming soon...', context);
        runFirst(() async {
          var notes = AppData.notesManager.allList.where((note) => note.text.trim().startsWith('[Repetido]'));
          if (notes.length == 2) {
            var notesDetails = '';
            for (var note in notes) {
              notesDetails +=
                  '{id:${note.id},text:${note.text},creationDateTime:${note.creationDateTime.toStr(DTToStrFormat.DATABASE)},modifDateTime:${note.modifDateTime.toStr(DTToStrFormat.DATABASE)}}';
            }
            await FirebaseCrashlytics.instance.recordError(Exception('Repeated records: $notesDetails'), StackTrace.current);
            await FirebaseCrashlytics.instance.sendUnsentReports();
          }
        });
      },
    );
  }

  Widget _about() {
    return ListTile(
      title: Text('About', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      onTap: () {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AboutPage()));
      },
    );
  }

  Widget _resetDontShowAgain(BuildContext context) {
    return ListTile(
      title: Text('Reset "Don\'t show this message again" checks', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      onTap: () {
        showDialog<String>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text('Do you want to reset the "Don\'t show this message again" checks?', style: Theme.of(context).textTheme.bodyLarge!),
              children: OptionTiles.build(context: context, options: {'Reset': Icons.restart_alt, 'Cancel': Icons.arrow_back}),
            );
          },
        ).then((value) {
          if (value == 'Reset') {
            AppData.settings[Settings.hideSendToTrashDialog]!.value = false.toString();
            AppData.settings[Settings.hideArchiveNotesDialog]!.value = false.toString();
            AppData.settings[Settings.hideRemovePermanentlyDialog]!.value = false.toString();
            AppData.settings[Settings.hideRemoveLabelDialog]!.value = false.toString();
            AppData.settings[Settings.hideDetachLabelDialog]!.value = false.toString();
            AppData.updateDbSettings([
              Settings.hideSendToTrashDialog,
              Settings.hideArchiveNotesDialog,
              Settings.hideRemovePermanentlyDialog,
              Settings.hideRemoveLabelDialog,
              Settings.hideDetachLabelDialog,
            ]);
            if (context.mounted) {
              t.showCustomToast('Checks were reset.', context);
            }
          }
        });
      },
    );
  }
}
