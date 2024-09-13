import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedopacity_change.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/views/dialogs/change_wallpaper_dialog.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/views/main_page/main_scaffold.dart';
import 'package:ohnote/constants.dart' as c;

class MainAppBar extends StatefulWidget {
  const MainAppBar({super.key});

  @override
  State<MainAppBar> createState() => _MainAppBarState();
}

class _MainAppBarState extends State<MainAppBar> with WidgetsBindingObserver {
  @override
  void initState() {
    //To enable didChangeAppLifecycleState()
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  //Used by WidgetsBinding.instance.addObserver(this)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && AppData.appliedWallpaper.value != null) {
      //precacheImage() allows to reload image when other than main page is opened and the app is sent to background.
      await precacheImage(AppData.appliedWallpaper.value!, context);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      leading: const SizedBox.shrink(),
      floating: false,
      pinned: true,
      snap: false,
      stretch: true,
      forceElevated: true, //Shadow.
      toolbarHeight: Theme.of(context).appBarTheme.toolbarHeight!,
      expandedHeight: 160.0,
      flexibleSpace: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          //Remember there might exist a flutter error when scrolling from bottom to top having lot of notes, but don't mind about it:
          //"Another exception was thrown: 'package:flutter/src/material/flexible_space_bar.dart': Failed assertion:
          //line 464 pos 12: 'needsCompositing': is not true."
          ValueListenableBuilder(
            valueListenable: AppData.notesManager.selectionQuantity,
            builder: (context, selectionQuantity, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.3,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: AppData.appliedWallpaper,
                          builder: (context, appliedWallpaper, child) {
                            return appliedWallpaper != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AnimatedOpacityChange(
                                        duration: Duration(milliseconds: c.animationDuration.inMilliseconds * 2),
                                        transitionColor: Theme.of(context).colorScheme.shadow,
                                        //The image is outside the InkWell to avoid the issue with opacity effect.
                                        child: Image(
                                          key: Key('wallpaper_${appliedWallpaper.assetName}'),
                                          width: 600.0,
                                          image: appliedWallpaper,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      //Material enables the splash effect that the image hides.
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onLongPress: () {
                                            if (_appBarPercent(constraints.maxHeight) > 0.0) {
                                              HapticFeedback.vibrate();
                                              ChangeWallpaperDialog.show(
                                                context: context,
                                              ).whenComplete(() {
                                                var settingsWallpaper = AppData.settings[Settings.wallpaper]!.value;
                                                if (appliedWallpaper.assetName != settingsWallpaper) {
                                                  AppData.appliedWallpaper.value = AssetImage(settingsWallpaper);
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    titlePadding: const EdgeInsets.only(left: 72.0, bottom: 10.0),
                    title: FractionallySizedBox(
                      widthFactor: 0.65,
                      child: AnimatedScaleText(
                        duration: c.animationDuration,
                        trueText: 'OhNote',
                        falseText: '$selectionQuantity selected',
                        condition: selectionQuantity == null,
                        textStyle:
                            Theme.of(context).appBarTheme.titleTextStyle!.copyWith(color: _foregroundColor(Theme.of(context), constraints.maxHeight)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return HeaderButtons(
                color: _foregroundColor(Theme.of(context), constraints.maxHeight),
                guiManager: AppData.notesManager,
                buttons: [
                  HeaderButton(HeaderButtonDetails.back),
                  HeaderButton(HeaderButtonDetails.navMenu)
                    ..showCaseKey = MainScaffold.of(context).navMenuSCK
                    ..showCaseDescription = 'This is the menu button,\nwhere settings, trash can,\nand other stuff are.',
                  HeaderButton(HeaderButtonDetails.selectionMode)
                    ..showCaseKey = MainScaffold.of(context).selectionModeSCK
                    ..showCaseDescription =
                        'If you want to do any\naction with your notes\nenter in selection mode\ntapping here to select\nthe notes.',
                  HeaderButton(HeaderButtonDetails.searchText)
                    ..showCaseKey = MainScaffold.of(context).searchSCK
                    ..showCaseDescription = 'Tap here to search\nnotes that match\nwith the typed text.',
                  HeaderButton(HeaderButtonDetails.more)
                    ..showCaseKey = MainScaffold.of(context).moreSCK
                    ..showCaseDescription = 'Tap here to view more\nactions you can do\nwith your notes.',
                  HeaderButton(HeaderButtonDetails.sortBy),
                  HeaderButton(HeaderButtonDetails.filters),
                  HeaderButton(HeaderButtonDetails.style),
                  HeaderButton(HeaderButtonDetails.favorite),
                  HeaderButton(HeaderButtonDetails.archive),
                  HeaderButton(HeaderButtonDetails.sendToTrash),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  //Sliver app bar min height = 79.0 and max height = 184.0 (verify with print(appBarHeight),
  //these values might change if something like padding is added).
  double _appBarPercent(double appBarHeight) => (appBarHeight - 79.0) / 105.0;

  Color _foregroundColor(ThemeData theme, double appBarHeight) {
    return Color.lerp(theme.colorScheme.primary, theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
        _appBarPercent(appBarHeight))!;
  }
}
