import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedopacity_change.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/splash_overlay.dart';
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
  static const _expandedHeight = 160.0;

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
      expandedHeight: _expandedHeight,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          var paddingOfTop = MediaQuery.paddingOf(context).top;
          var maxAppBarHeight = _expandedHeight + paddingOfTop;
          var minAppBarHeight = kToolbarHeight + paddingOfTop - 1.0;
          var appBarPercent = (constraints.maxHeight - minAppBarHeight) / (maxAppBarHeight - minAppBarHeight);
          return Stack(
            alignment: Alignment.bottomLeft,
            children: [
              //Remember there might exist a flutter error when scrolling from bottom to top having lot of notes, but don't mind about it:
              //"Another exception was thrown: 'package:flutter/src/material/flexible_space_bar.dart': Failed assertion:
              //line 464 pos 12: 'needsCompositing': is not true."
              ValueListenableBuilder(
                valueListenable: AppData.notesManager.selectionQuantity,
                builder: (context, selectionQuantity, child) {
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.3,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: AppData.appliedWallpaper,
                          builder: (context, appliedWallpaper, child) {
                            var shadowColor = Theme.of(context).colorScheme.shadow;
                            return appliedWallpaper != null
                                ?
                                //Material enables the splash effect that the image hides.
                                SplashOverlay(
                                    onLongPress: () {
                                      if (appBarPercent > 0.0) {
                                        HapticFeedback.vibrate();
                                        ChangeWallpaperDialog.show(
                                          context: context,
                                        ).whenComplete(() {
                                          var settingsWallpaper = AppData.settings[Settings.wallpaper]!.value;
                                          if (!appliedWallpaper.assetName.endsWith(settingsWallpaper)) {
                                            AppData.appliedWallpaper.value = AssetImage('assets/wallpapers/$settingsWallpaper');
                                          }
                                        });
                                      }
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        AnimatedOpacityChange(
                                          duration: Duration(milliseconds: c.animationDuration.inMilliseconds * 2),
                                          transitionColor: shadowColor,
                                          //Reminder: Image inside InkWell creates issue with opacity effect, So SplashOverlay is used.
                                          child: Image(
                                            key: Key('wpp_${appliedWallpaper.assetName}'),
                                            width: 600.0,
                                            image: appliedWallpaper,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              stops: const [0.075, 0.15, 0.25, 0.3, 0.35],
                                              colors: [
                                                shadowColor.withOpacity(0.8),
                                                shadowColor.withOpacity(0.6),
                                                shadowColor.withOpacity(0.15),
                                                shadowColor.withOpacity(0.05),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    titlePadding: const EdgeInsets.only(left: 72.0, bottom: 10.0),
                    title: IgnorePointer(
                      child: FractionallySizedBox(
                        widthFactor: 0.65,
                        child: AnimatedScaleText(
                          duration: c.animationDuration,
                          trueText: 'OhNote',
                          falseText: '$selectionQuantity selected',
                          condition: selectionQuantity == null,
                          textStyle: Theme.of(context).appBarTheme.titleTextStyle!.copyWith(
                                color: _foregroundColor(Theme.of(context), appBarPercent),
                                shadows: _shadows(Theme.of(context), appBarPercent),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              HeaderButtons(
                color: _foregroundColor(Theme.of(context), appBarPercent),
                shadows: _shadows(Theme.of(context), appBarPercent),
                guiManager: AppData.notesManager,
                updateDbFilters: true,
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
                  HeaderButton(HeaderButtonDetails.filters),
                  HeaderButton(HeaderButtonDetails.sortBy),
                  HeaderButton(HeaderButtonDetails.style),
                  HeaderButton(HeaderButtonDetails.favorite),
                  HeaderButton(HeaderButtonDetails.archive),
                  HeaderButton(HeaderButtonDetails.sendToTrash),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Color _foregroundColor(ThemeData theme, double appBarPercent) {
    return Color.lerp(
        theme.colorScheme.primary, theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary, appBarPercent)!;
  }

  List<Shadow> _shadows(ThemeData theme, double appBarPercent) {
    return [
      Shadow(
        color: theme.colorScheme.shadow.withOpacity(appBarPercent >= 0.5 ? appBarPercent - 0.5 : 0),
        blurRadius: 6.0,
        offset: const Offset(-1.0, 1.0),
      ),
    ];
  }
}
