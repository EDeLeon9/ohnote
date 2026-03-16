import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/home_widget_manager.dart';
import 'package:ohnote/tools/smooth_materialpageroute.dart';
import 'package:ohnote/tools/sized_showcase.dart';
import 'package:ohnote/view_components/filters_panel.dart';
import 'package:ohnote/views/bottomsheets/style_panel.dart';
import 'package:ohnote/views/home_widget_config_page.dart';
import 'package:ohnote/views/main_page/main_drawer.dart';
import 'package:ohnote/views/edit_note_page.dart';
import 'package:ohnote/views/main_page/main_appbar.dart';
import 'package:ohnote/views/main_page/main_list.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_nestedscrollview/flutter_nestedscrollview.dart' as custom;

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => MainScaffoldState();

  static MainScaffoldState of(BuildContext context) => context.findAncestorStateOfType<MainScaffoldState>()!;
}

class MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final _addNewNoteSCK = ShowCaseKey(FirstAccess.addNewNoteSC);
  final noteTileSCK = ShowCaseKey(FirstAccess.noteTileSC);
  final selectionModeSCK = ShowCaseKey(FirstAccess.selectionModeSC);
  final searchSCK = ShowCaseKey(FirstAccess.searchSC);
  final moreSCK = ShowCaseKey(FirstAccess.moreSC);
  final navMenuSCK = ShowCaseKey(FirstAccess.navMenuSC);
  final numberOfLinesSCK = ShowCaseKey(FirstAccess.numberOfLinesSC);
  final colorSCK = ShowCaseKey(FirstAccess.colorSC);
  final crossOutSCK = ShowCaseKey(FirstAccess.crossOutSC);
  final useCreationDateTimeSCK = ShowCaseKey(FirstAccess.useCreationDateTimeSC);

  @override
  void initState() {
    _setHomeWidgetClickFunctions();
    _runIfLaunchedFromHomeWidget(); //Forces to run the click function because _setHomeWidgetClickFunction was just called.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await _initialized();
      if (AppData.launchingFromHomeWidget == false) {
        Future.delayed(Duration(milliseconds: 750 - SizedShowCase.delay.inMilliseconds), _startShowCase);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppData.dataInitialized,
      builder: (context, dataInitialized, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop),
          child: ValueListenableBuilder(
            valueListenable: AppData.notesManager.stylePanelOpened,
            builder: (context, stylePanelOpened, child) {
              var stylePanelHeight = 0.0;
              var bottomIndent = 0.0;
              if (dataInitialized && stylePanelOpened) {
                stylePanelHeight = 196.0;
                bottomIndent = 35.0;
                if (AppData.notesManager.displayList.value?.any((e) => e.isChecked.value) == false) {
                  AppData.notesManager.styleSelectedNumberOfLines.value = int.parse(AppData.settings[Settings.defaultNumberOfLines]!.value);
                }
              }
              return Scaffold(
                key: _scaffoldKey,
                drawer:
                    dataInitialized
                        ? MainDrawer(
                          onSettingsClosed: () {
                            AppData.validateMaxHistory();
                            var settingsWallpaper = AppData.settings[Settings.wallpaper]!.value;
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (AppData.appliedWallpaper.value?.assetName.endsWith(settingsWallpaper) == false) {
                                AppData.appliedWallpaper.value = AssetImage('assets/wallpapers/$settingsWallpaper');
                              }
                              AppData.themeUpdatedFromSettings = false;
                            });
                            if (AppData.firstAccesses[FirstAccess.addNewNoteSC] == false) {
                              //Delay for reload the list
                              var listTemp = AppData.notesManager.displayList.value;
                              AppData.notesManager.displayList.value = [];
                              Future.delayed(const Duration(milliseconds: 10), () {
                                AppData.notesManager.displayList.value = listTemp;
                                _startShowCase();
                              });
                            }
                          },
                        )
                        : null,
                onDrawerChanged: (isOpened) {
                  AppData.notesManager.selectionQuantity.value = null;
                  AppData.notesManager.showSearchText.value = false;
                },
                resizeToAvoidBottomInset: false,
                floatingActionButton: _fab(stylePanelHeight: stylePanelHeight),
                body: SafeArea(
                  top: false,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AnimatedPadding(
                        duration: c.animationDuration,
                        padding: EdgeInsets.only(bottom: stylePanelHeight - bottomIndent),
                        child: custom.BouncingNestedScrollView(
                          headerSliverBuilder: (context, innerBoxIsScrolled) {
                            return [_header(nestedScrollViewContext: context)];
                          },
                          body: _body(bottomIndent: bottomIndent),
                        ),
                      ),
                      _stylePanel(stylePanelHeight: stylePanelHeight),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onPopInvoked(bool didPop) {
    if (!didPop && !SizedShowCase.next(context)) {
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        _scaffoldKey.currentState!.closeDrawer();
      } else {
        if (AppData.notesManager.selectionQuantity.value == null && !AppData.notesManager.showSearchText.value) {
          SystemNavigator.pop();
        }
        AppData.notesManager.selectionQuantity.value = null;
        AppData.notesManager.showSearchText.value = false;
      }
    }
  }

  Widget _header({required BuildContext nestedScrollViewContext}) {
    return custom.SliverOverlapAbsorber(
      //Required to avoid first note to go behind the app bar when is not necessary scrolling to bottom (e.g. having few notes).
      handle: custom.NestedScrollView.sliverOverlapAbsorberHandleFor(nestedScrollViewContext),
      sliver: const MainAppBar(),
    );
  }

  Widget _body({required double bottomIndent}) {
    //Builder required to get proper context for SliverOverlapInjector.
    return Builder(
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: AppData.notesManager.displayList,
          builder: (context, noteList, child) {
            return CustomScrollView(
              //The "controller" and "primary" members should be left unset, so that the NestedScrollView can control this inner
              //scroll view. If the "controller" property is set, then this scroll view will not be associated with the NestedScrollView.
              slivers: [
                custom.SliverOverlapInjector(handle: custom.NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
                ...(AppData.dataInitialized.value && noteList != null
                    ? [
                      SliverToBoxAdapter(
                        child: FiltersPanel(
                          guiManager: AppData.notesManager,
                          updateDbFilters: true,
                        ),
                      ),
                      MainList(noteList: noteList),
                    ]
                    : [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))]),
                SliverToBoxAdapter(child: SizedBox(height: bottomIndent)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _fab({required double stylePanelHeight}) {
    return AnimatedPadding(
      duration: c.animationDuration,
      padding: EdgeInsets.only(
        bottom: stylePanelHeight - (AppData.notesManager.stylePanelOpened.value && AppData.dataInitialized.value ? 45.0 : 0.0),
      ),
      child: SizedShowCase(
        showCaseKey: _addNewNoteSCK,
        description: 'Tap here to add a new note.',
        child: FloatingActionButton(
          tooltip: 'New note',
          onPressed: openNote,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _stylePanel({required double stylePanelHeight}) {
    return AppData.dataInitialized.value
        ? AnimatedContainer(
          duration: c.animationDuration,
          height: stylePanelHeight,
          onEnd: () {
            if (stylePanelHeight > 0) {
              if (AppData.notesManager.stylePanelOpened.value) {
                SizedShowCase.startShowCase(
                  context: context,
                  showCaseKeys: [numberOfLinesSCK, colorSCK, crossOutSCK, useCreationDateTimeSCK],
                  usePostFrameCallback: false,
                );
              }
            }
          },
          decoration:
              AppData.notesManager.stylePanelOpened.value
                  ? BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: c.roundedTopBorder.borderRadius,
                    border:
                        Theme.of(context).brightness == Brightness.dark
                            ? Border(top: BorderSide(color: Theme.of(context).colorScheme.outline))
                            : null,
                    boxShadow: const [BoxShadow(blurRadius: 5.0, spreadRadius: -2.0)],
                  )
                  : null,
          child: const StylePanel(),
        )
        : const SizedBox.shrink();
  }

  void openNote({Note? note, int? homeWidgetConfigId}) {
    if (mounted && AppData.dataInitialized.value && (AppData.launchingFromHomeWidget == false || (homeWidgetConfigId ?? 0) > 0)) {
      _scaffoldKey.currentState?.closeDrawer();
      AppData.notesManager.selectionQuantity.value = null;
      AppData.notesManager.showSearchText.value = false;
      Route page;
      if (note == null) {
        page = SmoothMaterialPageRoute(
          builder: (context) {
            var colorStr = AppData.settings[Settings.defaultColor]!.value;
            return EditNotePage(
              notes: [
                Note(
                  id: 0,
                  text: '',
                  guiManager: AppData.notesManager,
                  numberOfLines: int.parse(AppData.settings[Settings.defaultNumberOfLines]!.value),
                  color: colorStr != null.toString() ? Color(int.parse(colorStr)) : null,
                ),
              ],
              selectedNoteId: 0,
            );
          },
        );
      } else {
        var notes = [note];
        if (homeWidgetConfigId == null) {
          notes = List.of(AppData.notesManager.displayList.value!);
        } else {
          var homeWidgetConfig = AppData.homeWidgetConfigs.firstWhereOrNull((e) => e.id == homeWidgetConfigId);
          if (homeWidgetConfig?.notesManager.displayList.value?.contains(note) == true) {
            notes = List.of(homeWidgetConfig!.notesManager.displayList.value!);
          }
        }
        page = CupertinoPageRoute(builder: (context) => EditNotePage(notes: notes, selectedNoteId: note.id));
      }
      Navigator.push(context, page).whenComplete(() {
        if (AppData.notesManager.displayList.value?.isNotEmpty == true) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _startShowCase();
          });
        }
      });
    }
  }

  void _setHomeWidgetClickFunctions() {
    Future<void> prepareOpenFromHomeWidget() async {
      AppData.launchingFromHomeWidget = true;
      AppData.notesManager.selectionQuantity.value = null;
      AppData.notesManager.showSearchText.value = false;
      await _initialized();
      if (mounted) {
        Navigator.popUntil(
          context,
          (route) {
            return ModalRoute.isCurrentOf(context) == true;
          },
        );
      }
    }

    HomeWidgetManager.setClickFunction('opennote', (params) async {
      await prepareOpenFromHomeWidget();
      var noteId = int.tryParse(params['id'] ?? '');
      var homeWidgetConfigId = int.tryParse(params['configid'] ?? '');
      if (mounted && noteId != null) {
        if (noteId > 0) {
          var note = AppData.notesManager.allList.firstWhereOrNull((e) => e.id == noteId);
          if (note != null) {
            openNote(note: note, homeWidgetConfigId: homeWidgetConfigId);
          }
        } else {
          openNote(homeWidgetConfigId: homeWidgetConfigId);
        }
      }
      AppData.launchingFromHomeWidget = false;
    });
    HomeWidgetManager.setClickFunction('openhomewidgetconfigs', (params) async {
      await prepareOpenFromHomeWidget();
      if (mounted) {
        Navigator.push(context, SmoothMaterialPageRoute(builder: (context) => const HomeWidgetConfigPage()));
      }
      AppData.launchingFromHomeWidget = false;
    });
  }

  void _runIfLaunchedFromHomeWidget() async {
    AppData.launchingFromHomeWidget = null;
    AppData.notesManager.selectionQuantity.value = null;
    AppData.notesManager.showSearchText.value = false;
    var onTapFunction = await HomeWidgetManager.getFunctionIfLaunchedFromHomeWidget();
    if (onTapFunction != null) {
      onTapFunction();
    } else {
      AppData.launchingFromHomeWidget = false;
    }
  }

  Future<void> _initialized() async {
    while (!mounted || !AppData.dataInitialized.value || AppData.launchingFromHomeWidget == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  void _startShowCase() {
    var showCaseKeys = [_addNewNoteSCK];
    if (AppData.notesManager.displayList.value?.isNotEmpty == true) {
      showCaseKeys.addAll([noteTileSCK, selectionModeSCK, searchSCK, moreSCK, navMenuSCK]);
    }
    if (mounted) {
      SizedShowCase.startShowCase(
        context: context,
        showCaseKeys: showCaseKeys,
        usePostFrameCallback: false,
      );
    }
  }
}
