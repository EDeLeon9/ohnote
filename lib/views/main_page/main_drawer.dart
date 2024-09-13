import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/smooth_materialpageroute.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/views/archive_page.dart';
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
    _setTrashManagerList();
    _setArchiveManagerList();
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
              const SizedBox(height: 98.0), //Manual height applied doing tests.
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
            ],
          ),
          //Header (it is required to be above the rest of the widgets body to show the shadow).
          Column(
            children: [
              HeaderContainer(
                child: ListTile(
                  //TODO: what to do or place in this icon? also try CircleAvatar() class.
                  leading: Icon(Icons.account_circle, size: 50.0, color: fontColor),
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

  void _openPage<T>(Widget page, BuildContext context, [void Function(T? value)? whenCompletePage]) {
    Navigator.pop(context);
    _singleAsync.runFirst(() async {
      await Future.delayed(_drawerAnimationDuration);
      if (context.mounted) {
        Navigator.push(
          context,
          SmoothMaterialPageRoute<T>(builder: (context) => page),
        ).then((value) {
          whenCompletePage?.call(value);
        });
      }
    });
  }

  //This starts loading the trash can notes to have it ready before opening the trash can page.
  void _setTrashManagerList() async {
    await AppData.validateTimeInTrash();
    trashManager.allList = await AppData.queryNotes(
      guiManager: trashManager,
      where: 'trash_date_time IS NOT NULL',
    );
    trashManager.requestFilterList();
  }

  //This starts loading archive notes to have it ready before opening the archive page.
  void _setArchiveManagerList() async {
    archiveManager.allList = await AppData.queryNotes(
      guiManager: archiveManager,
      where: 'archive_date_time IS NOT NULL',
    );
    archiveManager.requestFilterList();
  }
}
