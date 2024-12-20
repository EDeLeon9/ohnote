import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/smooth_materialpageroute.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/views/archive_page.dart';
import 'package:ohnote/views/home_widget_config_page.dart';
import 'package:ohnote/views/labels_page.dart';
import 'package:ohnote/views/settings_page.dart';
import 'package:ohnote/views/trash_can_page.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/single_async.dart' as a;
import 'package:ohnote/tools/custom_toast.dart' as t;

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key, required this.onSettingsClosed});

  final void Function() onSettingsClosed;

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final _drawerAnimationDuration = const Duration(milliseconds: 246); //Drawer animation duration is 246.
  final _singleAsync = a.SingleAsync();
  late final GuiManager trashManager = GuiManager(
    sortComparison: (a, b) {
      int comparison = b.trashDateTime!.compareTo(a.trashDateTime!);
      if (comparison == 0) {
        comparison = a.userOrder.compareTo(b.userOrder);
      }
      return comparison;
    },
    getComparisonDateTime: (note) => note.trashDateTime!,
  );
  late final GuiManager archiveManager = GuiManager(
    sortComparison: (a, b) {
      int comparison = b.archiveDateTime!.compareTo(a.archiveDateTime!);
      if (comparison == 0) {
        comparison = a.userOrder.compareTo(b.userOrder);
      }
      return comparison;
    },
    getComparisonDateTime: (note) => note.archiveDateTime!,
  );

  @override
  void initState() {
    _setTrashManager();
    _setArchiveManager();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var fontColor = Theme.of(context).colorScheme.primary;
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 93.0), //Space of the HeaderContainer.
              ListTile(
                title: const Text('Labels'),
                leading: Icon(Icons.label, color: fontColor),
                onTap: () {
                  _openPage(const LabelsPage(), context);
                },
              ),
              ListTile(
                title: const Text('Archive'),
                leading: Icon(Icons.archive, color: fontColor),
                onTap: () {
                  _openPage(ArchivePage(archiveManager: archiveManager), context);
                },
              ),
              ListTile(
                title: const Text('Trash Can'),
                leading: Icon(Icons.delete, color: fontColor),
                onTap: () {
                  _openPage(TrashCanPage(trashManager: trashManager), context);
                },
              ),
              ListTile(
                title: const Text('Home Widget'),
                leading: Icon(Icons.add_to_home_screen, color: fontColor),
                onTap: () {
                  _openPage(const HomeWidgetConfigPage(), context);
                },
              ),
              c.defaultDivider,
              ListTile(
                title: const Text('Settings'),
                leading: Icon(Icons.settings, color: fontColor),
                onTap: () {
                  _openPage<Map<Settings, String>>(const SettingsPage(), context, (value) => widget.onSettingsClosed());
                },
              ),
              c.defaultDivider,
              ListTile(
                title: const Text('About'),
                leading: Icon(Icons.info, color: fontColor),
                onTap: () {
                  t.showCustomToast('Comming soon...', context);
                },
              ),
              //TODO: This backup option just for tests, comment this and AppData dbBackup function (and remove AndroidManifest.xml READ, WRITE and MANAGE uses-permission and requestLegacyExternalStorage).
              c.defaultDivider,
              ListTile(
                title: const Text('Backup'),
                leading: Icon(Icons.backup, color: fontColor),
                onTap: () async {
                  a.runFirst(
                    () async {
                      if (AppData.launchedFromHomeWidget == false) {
                        String msg;
                        if (await AppData.dbBackup()) {
                          msg = 'Backup performed successfully.';
                        } else {
                          msg = 'Error on performing backup.';
                        }
                        if (context.mounted) {
                          t.showCustomToast(msg, context);
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
          //Header is required to be above the rest of the widgets to spread the shadow.
          Column(
            children: [
              HeaderContainer(
                child: ListTile(
                  //TODO: Icons.account_circle as button for open/login account (also add option from settings), and remember to validate AppData.launchedFromHomeWidget == false for Icon action.
                  //leading: Icon(Icons.account_circle, size: 50.0, color: fontColor),
                  leading: Image(
                    height: 45.0,
                    width: 45.0,
                    image: AssetImage('assets/icon/icon_blue${Theme.of(context).brightness == Brightness.dark ? '_dark' : ''}.png'),
                  ),
                  tileColor: fontColor,
                  contentPadding: const EdgeInsets.fromLTRB(15.0, 30.0, 15.0, 6.0),
                  title: Column(
                    children: {
                      'Displayed notes': AppData.notesManager.displayList.value?.length ?? 0,
                      'Total notes': AppData.notesManager.allList.length,
                    }.entries.map((e) {
                      var textStyle = Theme.of(context).textTheme.bodyMedium;
                      return Row(
                        children: [
                          Text(e.key, style: textStyle),
                          const Spacer(),
                          Text(e.value.toString(), style: textStyle),
                          const SizedBox(width: 10.0),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  void _openPage<T>(Widget page, BuildContext context, [void Function(T? value)? whenClosingPage]) {
    if (AppData.launchedFromHomeWidget == false) {
      Navigator.pop(context);
      _singleAsync.runFirst(() async {
        await Future.delayed(_drawerAnimationDuration);
        if (context.mounted) {
          Navigator.push(
            context,
            SmoothMaterialPageRoute<T>(builder: (context) => page),
          ).then((value) {
            whenClosingPage?.call(value);
          });
        }
      });
    }
  }

  //This starts loading the trash can notes to have it ready before opening the trash can page.
  void _setTrashManager() async {
    await AppData.validateTimeInTrash();
    trashManager.allList = await AppData.queryNotes(
      guiManager: trashManager,
      where: 'trash_date_time IS NOT NULL',
    );
    trashManager.requestUpdateDisplayList();
  }

  //This starts loading archive notes to have it ready before opening the archive page.
  void _setArchiveManager() async {
    archiveManager.allList = await AppData.queryNotes(
      guiManager: archiveManager,
      where: 'archive_date_time IS NOT NULL',
    );
    archiveManager.requestUpdateDisplayList();
  }
}
