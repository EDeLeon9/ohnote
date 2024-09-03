import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/smooth_materialpageroute.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/view_components/filters_panel.dart';
import 'package:ohnote/views/style_panel.dart';
import 'package:ohnote/views/main_page/main_drawer.dart';
import 'package:ohnote/views/input_page.dart';
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
  late BuildContext _scaffoldContext;
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      while (!AppData.dataInitialized.value) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      Future.delayed(Duration(milliseconds: 750 - CustomShowCase.delay.inMilliseconds), _startShowCase);
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
          onPopInvoked: _onPopInvoked,
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
                drawer: MainDrawer(
                  onSettingsClosed: () {
                    AppData.validateMaxHistory();
                    var settingsWallpaper = AppData.settings[Settings.wallpaper]!.value;
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (AppData.appliedWallpaper.value?.assetName != settingsWallpaper) {
                        AppData.appliedWallpaper.value = AssetImage(settingsWallpaper);
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
                ),
                onDrawerChanged: (isOpened) {
                  if (AppData.notesManager.selectionQuantity.value != null) {
                    AppData.notesManager.selectionQuantity.value = null;
                  }
                  if (AppData.notesManager.showSearchText.value) {
                    AppData.notesManager.showSearchText.value = false;
                  }
                },
                body: Builder(
                  builder: (context) {
                    _scaffoldContext = context;
                    return Stack(
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
                    );
                  },
                ),
                resizeToAvoidBottomInset: false,
                floatingActionButton: _fab(stylePanelHeight: stylePanelHeight),
              );
            },
          ),
        );
      },
    );
  }

  void _onPopInvoked(bool didPop) {
    if (!didPop && !CustomShowCase.next(context)) {
      if (Scaffold.of(_scaffoldContext).isDrawerOpen) {
        Scaffold.of(_scaffoldContext).closeDrawer();
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
    //Is used SafeArea with slivers to avoid any horizontal disturbances (e.g. the "notch" on iOS when the phone is horizontal).
    return SafeArea(
      top: false,
      bottom: false,
      //Builder required to get proper context for SliverOverlapInjector.
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            //The "controller" and "primary" members should be left unset, so that the NestedScrollView can control this inner
            //scroll view. If the "controller" property is set, then this scroll view will not be associated with the NestedScrollView.
            slivers: [
              custom.SliverOverlapInjector(handle: custom.NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
              ...(AppData.dataInitialized.value
                  ? [
                      SliverToBoxAdapter(
                        child: FiltersPanel(
                          guiManager: AppData.notesManager,
                          updateDbFilters: true,
                        ),
                      ),
                      const MainList(),
                    ]
                  : [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))]),
              SliverToBoxAdapter(child: SizedBox(height: bottomIndent)),
            ],
          );
        },
      ),
    );
  }

  Widget _fab({required double stylePanelHeight}) {
    return AnimatedPadding(
      duration: c.animationDuration,
      padding:
          EdgeInsets.only(bottom: stylePanelHeight - (AppData.notesManager.stylePanelOpened.value && AppData.dataInitialized.value ? 45.0 : 0.0)),
      child: CustomShowCase(
        showCaseKey: _addNewNoteSCK,
        description: 'Tap here to add a new note.',
        child: FloatingActionButton(
          tooltip: 'New note',
          child: const Icon(Icons.add),
          onPressed: () {
            if (AppData.dataInitialized.value) {
              if (AppData.notesManager.selectionQuantity.value != null) {
                AppData.notesManager.selectionQuantity.value = null;
              }
              if (!AppData.notesManager.showSearchText.value) {
                AppData.notesManager.showSearchText.value = false;
              }
              Navigator.push(
                context,
                SmoothMaterialPageRoute(
                  builder: (context) {
                    var colorStr = AppData.settings[Settings.defaultColor]!.value;
                    return InputPage(
                      note: Note(
                        id: 0,
                        text: '',
                        guiManager: AppData.notesManager,
                        numberOfLines: int.parse(AppData.settings[Settings.defaultNumberOfLines]!.value),
                        color: colorStr != null.toString() ? Color(int.parse(colorStr)) : null,
                      ),
                    );
                  },
                ),
              ).whenComplete(() {
                if (AppData.notesManager.displayList.value?.isNotEmpty == true) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _startShowCase();
                  });
                }
              });
            }
          },
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
                  CustomShowCase.startShowCase(
                    context: context,
                    showCaseKeys: [numberOfLinesSCK, colorSCK, crossOutSCK, useCreationDateTimeSCK],
                    usePostFrameCallback: false,
                  );
                }
              }
            },
            decoration: AppData.notesManager.stylePanelOpened.value
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: c.roundedTopBorder.borderRadius,
                    boxShadow: const [BoxShadow(blurRadius: 5.0, spreadRadius: -2.0)],
                  )
                : null,
            child: const StylePanel(),
          )
        : const SizedBox.shrink();
  }

  void _startShowCase() {
    var showCaseKeys = [_addNewNoteSCK];
    if (AppData.notesManager.displayList.value?.isNotEmpty == true) {
      showCaseKeys.addAll([noteTileSCK, selectionModeSCK, searchSCK, moreSCK, navMenuSCK]);
    }
    if (context.mounted) {
      CustomShowCase.startShowCase(
        context: context,
        showCaseKeys: showCaseKeys,
        usePostFrameCallback: false,
      );
    }
  }
}
