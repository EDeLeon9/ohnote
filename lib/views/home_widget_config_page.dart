import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/home_widget_config.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/splash_overlay.dart';
import 'package:ohnote/view_components/gui_item_tile.dart';
import 'package:ohnote/view_components/gui_listview_builder.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/views/dialogs/home_widget_config_dialog.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/single_async.dart' as a;

class HomeWidgetConfigPage extends StatefulWidget {
  const HomeWidgetConfigPage({super.key});

  @override
  State<HomeWidgetConfigPage> createState() => _HomeWidgetConfigPageState();
}

class _HomeWidgetConfigPageState extends State<HomeWidgetConfigPage> {
  final _appTheme = AppTheme();
  late final _backgroundAlignmentLerp = Random().nextDouble();
  final _newHomeWidgetConfigSCK = ShowCaseKey(FirstAccess.newHomeWidgetConfigSC);
  final _homeWidgetConfigMoreSCK = ShowCaseKey(FirstAccess.homeWidgetConfigMoreSC);
  final GuiManager _homeWidgetConfigManager = GuiManager(
    sortComparison: (a, b) => a.creationDateTime.compareTo(b.creationDateTime),
    getComparisonDateTime: (note) => note.creationDateTime, //Not used.
  );

  @override
  void initState() {
    _homeWidgetConfigManager.allList = AppData.homeWidgetConfigs
        .map((e) => Note(
              id: e.id,
              text: e.title,
              color: Colors.black.withOpacity(e.opacity / 100.0),
              creationDateTime: e.creationDateTime,
              guiManager: _homeWidgetConfigManager,
            ))
        .toList();
    _homeWidgetConfigManager.allList.sort(_homeWidgetConfigManager.sortComparison);
    _homeWidgetConfigManager.requestUpdateDisplayList();
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: [_newHomeWidgetConfigSCK, _homeWidgetConfigMoreSCK],
      usePostFrameCallback: true,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop, context),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey,
        appBar: AppBar(
          title: ValueListenableBuilder(
            valueListenable: _homeWidgetConfigManager.selectionQuantity,
            builder: (context, selectionQuantity, child) {
              return AnimatedScaleText(
                duration: c.animationDuration,
                trueText: 'Home Widget\nConfigurations',
                falseText: '$selectionQuantity selected',
                condition: selectionQuantity == null,
                textStyle: selectionQuantity == null ? const TextStyle(fontSize: 18.0) : null,
              );
            },
          ),
          actions: [
            HeaderButtons.selectionModeButton(
              context: context,
              guiManager: _homeWidgetConfigManager,
              button: HeaderButton(HeaderButtonDetails.selectionMode),
            ),
            _newHomeWidgetConfigButton(),
            HeaderButtons.moreButton(
              context: context,
              button: HeaderButton(HeaderButtonDetails.more)
                ..showCaseKey = _homeWidgetConfigMoreSCK
                ..showCaseDescription =
                    'To remove a home\nwidget configuration\ntap on the option in\nthis menu. You must\nfirst select the confi-\nguration you want to\nremove.',
              moreButtons: [
                HeaderButton(HeaderButtonDetails.removeHomeWidgetConfig),
              ],
              onSelected: (selected) {
                if (selected == HeaderButtonDetails.removeHomeWidgetConfig) {
                  _removeHomeWidgetConfig();
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              alignment: Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, _backgroundAlignmentLerp)!,
              image: AppData.appliedWallpaper.value!,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: SafeArea(
              child: GuiListViewBuilder(
                expand: false,
                guiManager: _homeWidgetConfigManager,
                itemBuilder: (context, index, item, displayList) {
                  return GuiItemTile(
                    key: Key('hwc_${item.id}'),
                    item: item,
                    keysPrefix: 'hwc',
                    tilePadding: EdgeInsets.fromLTRB(16.0, index == 0 ? 12.0 : 0.0, 16.0, 15.0),
                    contentbuilder: (onTapPerformed, onLongPress) {
                      var homeWidgetConfig = AppData.homeWidgetConfigs.firstWhere((e) => e.id == item.id);
                      return Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15.0))),
                        child: SplashOverlay(
                          onTap: () {
                            if (onTapPerformed()) {
                              _editHomeWidgetConfig(homeWidgetConfig);
                            }
                          },
                          onLongPress: onLongPress,
                          child: _tileContent(homeWidgetConfig),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPopInvoked(bool didPop, BuildContext context) {
    if (!didPop && !CustomShowCase.next(context)) {
      if (_homeWidgetConfigManager.selectionQuantity.value == null) {
        Navigator.pop(context);
      }
      _homeWidgetConfigManager.selectionQuantity.value = null;
    }
  }

  void _editHomeWidgetConfig([HomeWidgetConfig? homeWidgetConfig]) {
    _homeWidgetConfigManager.selectionQuantity.value = null;
    HomeWidgetConfigDialog.show(
      context: context,
      homeWidgetConfig: homeWidgetConfig,
    ).then((value) {
      if (value != null) {
        Note hwcNote;
        bool isNew = false;
        _homeWidgetConfigManager.displayList.value = null;
        if (homeWidgetConfig == null) {
          isNew = true;
          AppData.homeWidgetConfigs.sort((a, b) => a.id.compareTo(b.id));
          int id = (AppData.homeWidgetConfigs.lastWhereOrNull((e) => e.id == AppData.homeWidgetConfigs.indexOf(e) + 1)?.id ?? 0) + 1;
          homeWidgetConfig = HomeWidgetConfig(id: id, creationDateTime: DateTime.now());
          AppData.homeWidgetConfigs.insert(id - 1, homeWidgetConfig!);
          hwcNote = Note(
            id: id,
            text: value.title,
            guiManager: _homeWidgetConfigManager,
            creationDateTime: homeWidgetConfig!.creationDateTime,
          );
          _homeWidgetConfigManager.allList.add(hwcNote);
          _homeWidgetConfigManager.allList.sort(_homeWidgetConfigManager.sortComparison);
        } else {
          hwcNote = _homeWidgetConfigManager.allList.where((e) => e.id == homeWidgetConfig!.id).first;
          hwcNote.text = value.title;
        }
        hwcNote.color.value = Colors.black.withOpacity(value.opacity / 100.0);
        homeWidgetConfig!.copyFrom(value);
        _homeWidgetConfigManager.requestUpdateDisplayList();
        AppData.updateDbHomeWidgetConfig(homeWidgetConfig!, isNew);
        AppData.updateHomeWidget(true);
      }
    });
  }

  void _removeHomeWidgetConfig() {
    a.runFirst(() async {
      await _homeWidgetConfigManager.startSlideAnimation(
        context: context,
        slideAnimationState: -1,
        afterAnimationStateAction: (selectedHomeWidgetConfigs) {
          var maxIdBeforeDeleting = AppData.homeWidgetConfigs.map((e) => e.id).max;
          AppData.removeHomeWidgetConfigs(selectedHomeWidgetConfigs.map((e) => e.id).toList());
          AppData.updateHomeWidget(true, maxIdBeforeDeleting);
          AppData.removeNotesFromLists(selectedHomeWidgetConfigs, _homeWidgetConfigManager);
        },
        successMessage: 'Selected configurations were removed.',
        itemsNoun: 'configurations',
        confirmationDialog: () {
          return ConfirmationDialog.show(
            context: context,
            caption: 'Do you want to remove the selected configurations?\nYou will need to remove any widget using this configuration.',
            confirmOption: 'Remove',
            confirmOptionIcon: Icons.delete_forever,
            dontShowAgainChecked: AppData.settings[Settings.hideRemoveHomeWidgetConfigDialog]!.value == true.toString(),
            setDontShowAgain: () {
              AppData.settings[Settings.hideRemoveHomeWidgetConfigDialog]!.value = true.toString();
              AppData.updateDbSettings([Settings.hideRemoveHomeWidgetConfigDialog]);
            },
          );
        },
      );
    });
  }

  Widget _newHomeWidgetConfigButton() {
    return CustomShowCase(
      showCaseKey: _newHomeWidgetConfigSCK,
      description:
          'Tap here to create a\nhome widget configu-\nration that you can use\nto add a widget to your\nhome screen. You can\neven edit it later and\nyour home screen\nwidget will be updated\nas well.',
      child: IconButton(
        tooltip: 'New home widget configuration',
        icon: const Icon(Icons.add_card),
        onPressed: () {
          _editHomeWidgetConfig();
        },
      ),
    );
  }

  Widget _tileContent(HomeWidgetConfig homeWidgetConfig) {
    var textItems = <String>[
      'Title: ${homeWidgetConfig.title}',
      'Theme: ${homeWidgetConfig.theme.caption}',
      'Opacity: ${homeWidgetConfig.opacity}%',
      ...homeWidgetConfig.notesManager.filters.value.getAppliedCaptions(true),
    ];
    var brightness = homeWidgetConfig.theme == AppThemeBrightness.light
        ? Brightness.light
        : (homeWidgetConfig.theme == AppThemeBrightness.dark ? Brightness.dark : Theme.of(context).brightness);
    return Theme(
      data: brightness == Brightness.dark ? _appTheme.darkTheme : _appTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Stack(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 200.0),
                color: Theme.of(context).colorScheme.surface.withOpacity(homeWidgetConfig.opacity / 100.0),
                child: Column(
                  children: [
                    const SizedBox(height: 35.0), //Space for the HeaderContainer.
                    ListView.separated(
                      shrinkWrap: true, //Avoids error related of infinite height.
                      itemCount: textItems.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            textItems[index],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => Divider(height: 0.0, color: Colors.grey.withOpacity(0.35)),
                    ),
                    const SizedBox(height: 1.0),
                  ],
                ),
              ),
              //Header is required to be above the rest of the widgets to spread the shadow.
              HeaderContainer(
                child: Padding(
                  padding: const EdgeInsets.only(left: 11.0, right: 5.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1.0),
                        child: Text(
                          homeWidgetConfig.title,
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          minimumSize: Size.zero,
                          visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                          padding: const EdgeInsets.all(0.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0)),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {},
                        child: SizedBox(
                          height: 23.0,
                          width: 23.0,
                          child: const Icon(Icons.add, size: 17.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
