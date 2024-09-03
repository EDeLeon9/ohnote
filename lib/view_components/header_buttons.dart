import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animatedscale_button.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/tools/tappable_popupmenubutton.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/views/filters_dialog.dart';
import 'package:ohnote/tools/custom_toast.dart' as t;
import 'package:ohnote/tools/single_async.dart' as a;
import 'package:ohnote/constants.dart' as c;

enum HeaderButtonDetails {
  back('Back', Icons.arrow_back),
  navMenu('Navigation menu', Icons.menu),
  selectionMode('Selection mode', Icons.library_add_check_outlined),
  selectAll('Select all', Icons.select_all),
  deselectAll('Deselect all', Icons.deselect),
  searchText('Search text', Icons.search),
  more('More', Icons.more_vert),
  filters('Filters', Icons.filter_alt),
  style('Style', Icons.style),
  favorite('Favorite', Icons.star),
  archive('Archive', Icons.archive),
  history('History', Icons.history),
  sendToTrash('Send to trash', Icons.delete),
  discardHistory('Discard', Icons.delete_forever),
  restore('Restore', Icons.restore_page),
  removePermanently('Remove permanently', Icons.delete_forever),
  searchLabel('Search label', Icons.search),
  removeLabel('Remove label', Icons.delete_forever);

  final String caption;
  final IconData icon;

  const HeaderButtonDetails(this.caption, this.icon);
}

class HeaderButton {
  HeaderButton(this.details);
  final HeaderButtonDetails details;
  ShowCaseKey<FirstAccess>? showCaseKey;
  String? showCaseDescription;

  Widget build({
    Color? color,
    required void Function() onPressed,
    bool? isVisible,
  }) {
    if (AppData.dataInitialized.value) {
      Widget button = AnimatedScaleButton(
        duration: c.animationDuration,
        tooltip: details.caption,
        icon: details.icon,
        color: color,
        isVisible: isVisible != false,
        onPressed: onPressed,
      );
      if (showCaseKey != null) {
        button = CustomShowCase(
          showCaseKey: showCaseKey!,
          description: showCaseDescription!,
          child: button,
        );
      }
      return button;
    }
    return const SizedBox.shrink();
  }
}

class HeaderButtons extends StatelessWidget {
  HeaderButtons({
    super.key,
    this.title,
    this.color,
    required this.guiManager,
    required this.buttons,
    this.padding,
    this.largeMainButtons = true,
  });

  final String? title;
  final Color? color;
  final GuiManager guiManager;
  final List<HeaderButton> buttons;
  final EdgeInsets? padding;
  final bool largeMainButtons;
  late final buttonsMap = Map.fromEntries(buttons.map((e) => MapEntry(e.details, e)));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ValueListenableBuilder(
        valueListenable: guiManager.selectionQuantity,
        builder: (context, selectionQuantity, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: AppData.dataInitialized, //Used by HeaderButton class.
                builder: (context, dataInitialized, child) {
                  return ValueListenableBuilder(
                    valueListenable: guiManager.showSearchText,
                    builder: (context, showSearchText, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(width: largeMainButtons ? 0.0 : 1.4),
                          Stack(
                            children: [
                              _navMenuButton(
                                isVisible: selectionQuantity == null && !showSearchText,
                                context: context,
                                button: buttonsMap[HeaderButtonDetails.navMenu],
                              ),
                              _backButton(
                                isVisible: selectionQuantity != null || showSearchText,
                                button: buttonsMap[HeaderButtonDetails.back],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Padding(
                            padding: largeMainButtons ? const EdgeInsets.only(bottom: 4.0) : EdgeInsets.zero,
                            child: Row(
                              children: [
                                HeaderButtons.selectionModeButton(
                                  context: context,
                                  color: color,
                                  guiManager: guiManager,
                                  button: buttonsMap[HeaderButtonDetails.selectionMode],
                                ),
                                searchTextButton(
                                  color: color,
                                  guiManager: guiManager,
                                  button: buttonsMap[HeaderButtonDetails.searchText],
                                ),
                                moreButton(
                                  context: context,
                                  color: color,
                                  button: buttonsMap[HeaderButtonDetails.more],
                                  moreButtons: [
                                    buttonsMap[HeaderButtonDetails.filters],
                                    buttonsMap[HeaderButtonDetails.style],
                                    buttonsMap[HeaderButtonDetails.favorite],
                                    buttonsMap[HeaderButtonDetails.archive],
                                    buttonsMap[HeaderButtonDetails.sendToTrash],
                                    buttonsMap[HeaderButtonDetails.discardHistory],
                                  ].whereNotNull().toList(),
                                  onSelected: (selected) {
                                    if (selected == HeaderButtonDetails.filters) {
                                      filtersPressed(context: context, guiManager: guiManager);
                                    } else if (selected == HeaderButtonDetails.style) {
                                      _stylePressed(guiManager: guiManager);
                                    } else if (selected == HeaderButtonDetails.favorite) {
                                      _favoritePressed(context: context);
                                    } else if (selected == HeaderButtonDetails.archive) {
                                      _archivePressed(context: context);
                                    } else if (selected == HeaderButtonDetails.sendToTrash) {
                                      _sendToTrashPressed(context: context);
                                    } else if (selected == HeaderButtonDetails.discardHistory) {
                                      _discardHistoryPressed(context: context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 1.4),
                        ],
                      );
                    },
                  );
                },
              ),
              title != null
                  ? AnimatedScaleText(
                      duration: c.animationDuration,
                      trueText: title!,
                      falseText: '$selectionQuantity selected',
                      condition: selectionQuantity == null,
                      textStyle: Theme.of(context).textTheme.titleLarge!.copyWith(color: color ?? Theme.of(context).colorScheme.primary),
                    )
                  : const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  Widget _navMenuButton({
    required BuildContext context,
    required bool isVisible,
    required HeaderButton? button,
  }) {
    return button != null
        ? SizedBox(
            height: largeMainButtons ? 56.0 : null,
            width: largeMainButtons ? 56.0 : null,
            child: button.build(
              color: color,
              isVisible: isVisible,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _backButton({
    required isVisible,
    required HeaderButton? button,
  }) {
    return button != null
        ? SizedBox(
            height: largeMainButtons ? 56.0 : null,
            width: largeMainButtons ? 56.0 : null,
            child: button.build(
              color: color,
              isVisible: isVisible,
              onPressed: () {
                guiManager.selectionQuantity.value = null;
                guiManager.showSearchText.value = false;
              },
            ),
          )
        : const SizedBox.shrink();
  }

  static Widget selectionModeButton({
    required BuildContext context,
    Color? color,
    required GuiManager guiManager,
    required HeaderButton? button,
  }) {
    return button != null
        ? ValueListenableBuilder(
            valueListenable: guiManager.selectionQuantity,
            builder: (context, selectionQuantity, child) {
              return ValueListenableBuilder(
                valueListenable: guiManager.isAllSelected,
                builder: (context, isAllSelected, child) {
                  return Stack(
                    children: [
                      button.build(
                        color: color,
                        isVisible: selectionQuantity == null,
                        onPressed: () {
                          guiManager.isManualSelection = true;
                        },
                      ),
                      HeaderButton(HeaderButtonDetails.selectAll).build(
                        color: color,
                        isVisible: selectionQuantity != null && !isAllSelected,
                        onPressed: () {
                          guiManager.setIsCheckedToAll(true);
                          guiManager.setSelectionQuantity();
                        },
                      ),
                      HeaderButton(HeaderButtonDetails.deselectAll).build(
                        color: color,
                        isVisible: selectionQuantity != null && isAllSelected,
                        onPressed: () {
                          guiManager.setIsCheckedToAll(false);
                          guiManager.setSelectionQuantity();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          )
        : const SizedBox.shrink();
  }

  static Widget searchTextButton({
    Color? color,
    required GuiManager guiManager,
    required HeaderButton? button,
  }) {
    return button != null
        ? button.build(
            color: color,
            onPressed: () {
              guiManager.showSearchText.value = true;
              guiManager.searchTextFocusNode.requestFocus();
            },
          )
        : const SizedBox.shrink();
  }

  static Widget moreButton({
    required BuildContext context,
    Color? color,
    required List<HeaderButton> moreButtons,
    required void Function(HeaderButtonDetails? selected) onSelected,
    required HeaderButton? button,
  }) {
    return button != null
        ? TappablePopupMenuButton(
            childButtonBuilder: (showButtonMenuAction) {
              return button.build(
                color: color,
                onPressed: showButtonMenuAction,
              );
            },
            items: moreButtons
                .map((e) => PopupMenuItem<HeaderButtonDetails>(
                      value: e.details,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        title: Text(e.details.caption),
                        leading: Icon(e.details.icon, color: Theme.of(context).colorScheme.primary),
                      ),
                    ))
                .toList(),
            onSelected: onSelected,
          )
        : const SizedBox.shrink();
  }

  static void filtersPressed({required BuildContext context, required GuiManager guiManager}) {
    guiManager.setStyleColors();
    FiltersDialog.show(context: context, guiManager: guiManager).then((value) {
      if (value != null) {
        guiManager.filters.value.copyFrom(value);
        guiManager.filters.notifyListeners();
        if (guiManager.filters.value.text == '') {
          guiManager.showSearchText.value = false;
        }
        AppData.updateDbFilters();
      }
    });
  }

  static void restorePressed({required BuildContext context, required GuiManager guiManager}) {
    a.runFirst(() async {
      await guiManager.startSlideAnimation(
        context: context,
        slideAnimationState: -1,
        afterAnimationStateAction: (selectedNotes) {
          AppData.restoreNotes(selectedNotes);
          AppData.removeNotesFromLists(selectedNotes, guiManager);
        },
        successMessage: 'Your notes were restored.',
      );
    });
  }

  void _stylePressed({required GuiManager guiManager}) {
    if (!guiManager.stylePanelOpened.value) {
      guiManager.setStyleColors();
      guiManager.stylePanelOpened.value = true;
    }
    guiManager.isManualSelection = true;
  }

  void _favoritePressed({required BuildContext context}) {
    if (guiManager.selectionQuantity.value != null) {
      var selectedNotes = guiManager.getSelectedNotes();
      if (selectedNotes.isNotEmpty) {
        var favoriteState = selectedNotes.any((e) => !e.favorite.value);
        var notesToUpdate = selectedNotes.where((e) => e.favorite.value == !favoriteState).toList();
        for (var note in notesToUpdate) {
          note.favorite.value = favoriteState;
        }
        AppData.updateDbNotes(notesToUpdate, 'favorite', '${favoriteState ? 1 : 0}');
      } else {
        t.showCustomToast('No notes selected.', context);
      }
    } else {
      guiManager.isManualSelection = true;
      t.showCustomToast('First select the notes.', context);
    }
  }

  void _archivePressed({required BuildContext context}) {
    a.runFirst(() async {
      await guiManager.startSlideAnimation(
        context: context,
        slideAnimationState: -1,
        afterAnimationStateAction: (selectedNotes) {
          AppData.archiveNotes(selectedNotes);
        },
        successMessage: 'Selected notes were archived.',
        confirmationDialog: () {
          return ConfirmationDialog.show(
            context: context,
            caption: 'Do you want to archive the selected notes?',
            confirmOption: 'Archive',
            confirmOptionIcon: Icons.archive,
            dontShowAgainChecked: AppData.settings[Settings.hideArchiveNotesDialog]!.value == true.toString(),
            setDontShowAgain: () {
              AppData.settings[Settings.hideArchiveNotesDialog]!.value = true.toString();
              AppData.updateDbSettings([Settings.hideArchiveNotesDialog]);
            },
          );
        },
      );
    });
  }

  void _sendToTrashPressed({required BuildContext context}) {
    a.runFirst(() async {
      await guiManager.startSlideAnimation(
        context: context,
        slideAnimationState: 1,
        afterAnimationStateAction: (selectedNotes) {
          AppData.sendNotesToTrash(selectedNotes);
        },
        successMessage: 'Selected notes sent to trash can.',
        confirmationDialog: () {
          return ConfirmationDialog.show(
            context: context,
            caption: 'Do you want to send the selected notes to trash can?',
            confirmOption: 'Send to trash can',
            confirmOptionIcon: Icons.delete,
            dontShowAgainChecked: AppData.settings[Settings.hideSendToTrashDialog]!.value == true.toString(),
            setDontShowAgain: () {
              AppData.settings[Settings.hideSendToTrashDialog]!.value = true.toString();
              AppData.updateDbSettings([Settings.hideSendToTrashDialog]);
            },
          );
        },
      );
    });
  }

  void _discardHistoryPressed({required BuildContext context}) {
    a.runFirst(() async {
      await guiManager.startSlideAnimation(
        context: context,
        slideAnimationState: 1,
        afterAnimationStateAction: (selectedNotes) {
          AppData.removeDbHistory(selectedNotes);
          AppData.removeNotesFromLists(selectedNotes, guiManager);
        },
        successMessage: 'The selected history was discarded.',
        itemsNoun: 'history',
      );
    });
  }
}
