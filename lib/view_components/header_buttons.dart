import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/data/sort_by.dart';
import 'package:ohnote/tools/animated/animatedscale_button.dart';
import 'package:ohnote/tools/animated/animatedscale_text.dart';
import 'package:ohnote/tools/color_to_int_converter.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/tools/tappable_popupmenubutton.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/views/dialogs/filters_dialog.dart';
import 'package:ohnote/views/dialogs/sortby_dialog.dart';
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
  sortBy('Sort by', Icons.sort),
  filters('Filters', Icons.filter_alt),
  style('Style', Icons.style),
  favorite('Favorite', Icons.star),
  archive('Archive', Icons.archive),
  history('History', Icons.history),
  sendToTrash('Send to trash', Icons.delete),
  discardHistory('Discard', Icons.delete_forever),
  restore('Restore', Icons.restore_page),
  removePermanently('Remove permanently', Icons.delete_forever),
  labelNote('Label note', Icons.label),
  searchLabel('Search label', Icons.search),
  removeLabel('Remove label', Icons.delete_forever),
  removeHomeWidgetConfig('Remove home widget\nconfiguration', Icons.delete_forever);

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
    List<Shadow>? shadows,
    required void Function() onPressed,
    bool? isVisible,
  }) {
    if (AppData.dataInitialized.value) {
      Widget button = AnimatedScaleButton(
        duration: c.animationDuration,
        tooltip: details.caption,
        icon: details.icon,
        color: color,
        shadows: shadows,
        isVisible: isVisible != false,
        onPressed: () {
          if (AppData.launchingFromHomeWidget == false) {
            onPressed();
          }
        },
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

class HeaderButtons extends StatefulWidget {
  const HeaderButtons({
    super.key,
    this.title,
    this.color,
    this.shadows,
    required this.guiManager,
    required this.buttons,
    this.padding,
    this.updateDbFilters = false,
  });

  final String? title;
  final Color? color;
  final List<Shadow>? shadows;
  final GuiManager guiManager;
  final List<HeaderButton> buttons;
  final EdgeInsets? padding;
  final bool updateDbFilters;

  @override
  State<HeaderButtons> createState() => _HeaderButtonsState();

  Widget _navMenuButton({
    required BuildContext context,
    required bool isVisible,
    required HeaderButton? button,
  }) {
    return button != null
        ? button.build(
          color: color,
          shadows: shadows,
          isVisible: isVisible,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        )
        : const SizedBox.shrink();
  }

  Widget _backButton({
    required isVisible,
    required HeaderButton? button,
    List<Shadow>? shadows,
  }) {
    return button != null
        ? button.build(
          color: color,
          shadows: shadows,
          isVisible: isVisible,
          onPressed: () {
            guiManager.selectionQuantity.value = null;
            guiManager.showSearchText.value = false;
          },
        )
        : const SizedBox.shrink();
  }

  static Widget selectionModeButton({
    required BuildContext context,
    Color? color,
    List<Shadow>? shadows,
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
                      shadows: shadows,
                      isVisible: selectionQuantity == null,
                      onPressed: () {
                        guiManager.isManualSelection = true;
                      },
                    ),
                    HeaderButton(HeaderButtonDetails.selectAll).build(
                      color: color,
                      shadows: shadows,
                      isVisible: selectionQuantity != null && !isAllSelected,
                      onPressed: () {
                        guiManager.setIsCheckedToAll(true);
                        guiManager.setSelectionQuantity();
                      },
                    ),
                    HeaderButton(HeaderButtonDetails.deselectAll).build(
                      color: color,
                      shadows: shadows,
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
    List<Shadow>? shadows,
    required GuiManager guiManager,
    required HeaderButton? button,
  }) {
    return button != null
        ? button.build(
          color: color,
          shadows: shadows,
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
    List<Shadow>? shadows,
    required List<HeaderButton> moreButtons,
    required void Function(HeaderButtonDetails? selected) onSelected,
    required HeaderButton? button,
  }) {
    return button != null
        ? TappablePopupMenuButton(
          childButtonBuilder: (showButtonMenuAction) {
            return button.build(
              color: color,
              shadows: shadows,
              onPressed: showButtonMenuAction,
            );
          },
          items:
              moreButtons
                  .map(
                    (e) => PopupMenuItem<HeaderButtonDetails>(
                      value: e.details,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                        title: Text(e.details.caption),
                        leading: Icon(e.details.icon, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  )
                  .toList(),
          onSelected: onSelected,
        )
        : const SizedBox.shrink();
  }

  void _sortByPressed({required BuildContext context, required GuiManager guiManager}) {
    SortByDialog.show(
      context: context,
    ).then((value) {
      if (value != null) {
        int Function(Note a, Note b) comparison;
        switch (value.sortBy) {
          case SortBy.text:
            comparison = (Note a, Note b) => a.text.compareTo(b.text);
            break;
          case SortBy.date:
            comparison = (Note a, Note b) => guiManager.getComparisonDateTime(a).compareTo(guiManager.getComparisonDateTime(b));
            break;
          case SortBy.color:
            comparison = (Note a, Note b) => (b.color.value ?? Colors.transparent).toInt().compareTo((a.color.value ?? Colors.transparent).toInt());
            break;
          case SortBy.label:
            comparison = (Note a, Note b) {
              if (a.labelIds.isNotEmpty && b.labelIds.isNotEmpty) {
                return AppData.labelIds.indexOf(a.labelIds.first).compareTo(AppData.labelIds.indexOf(b.labelIds.first));
              }
              return (a.labelIds.isNotEmpty ? 0 : 1).compareTo(b.labelIds.isNotEmpty ? 0 : 1);
            };
            break;
          case SortBy.favorite:
            comparison = (Note a, Note b) => (a.favorite.value ? 0 : 1).compareTo(b.favorite.value ? 0 : 1);
            break;
          case SortBy.crossedOut:
            comparison = (Note a, Note b) => (a.isCrossedOut.value ? 0 : 1).compareTo(b.isCrossedOut.value ? 0 : 1);
            break;
        }
        AppData.sortNotes(comparison, value.order);
      }
    });
  }

  static void filtersPressed({required BuildContext context, required GuiManager guiManager, required bool updateDb}) {
    FiltersDialog.show(
      context: context,
      guiManager: guiManager,
    ).then((value) {
      if (value != null) {
        guiManager.filters.value.copyFrom(value);
        guiManager.filters.notifyListeners();
        if (guiManager.filters.value.text == '') {
          guiManager.showSearchText.value = false;
        }
        if (updateDb) {
          AppData.updateDbFilters(guiManager.filters.value);
        }
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
      guiManager.updateStyleColors();
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

class _HeaderButtonsState extends State<HeaderButtons> {
  late final buttonsMap = Map.fromEntries(widget.buttons.map((e) => MapEntry(e.details, e)));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: ValueListenableBuilder(
        valueListenable: widget.guiManager.selectionQuantity,
        builder: (context, selectionQuantity, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: AppData.dataInitialized, //Used by HeaderButton class.
                builder: (context, dataInitialized, child) {
                  return ValueListenableBuilder(
                    valueListenable: widget.guiManager.showSearchText,
                    builder: (context, showSearchText, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(width: 1.4),
                          Stack(
                            children: [
                              widget._navMenuButton(
                                isVisible: selectionQuantity == null && !showSearchText,
                                context: context,
                                button: buttonsMap[HeaderButtonDetails.navMenu],
                              ),
                              widget._backButton(
                                isVisible: selectionQuantity != null || showSearchText,
                                button: buttonsMap[HeaderButtonDetails.back],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              HeaderButtons.selectionModeButton(
                                context: context,
                                color: widget.color,
                                shadows: widget.shadows,
                                guiManager: widget.guiManager,
                                button: buttonsMap[HeaderButtonDetails.selectionMode],
                              ),
                              HeaderButtons.searchTextButton(
                                color: widget.color,
                                shadows: widget.shadows,
                                guiManager: widget.guiManager,
                                button: buttonsMap[HeaderButtonDetails.searchText],
                              ),
                              HeaderButtons.moreButton(
                                context: context,
                                color: widget.color,
                                shadows: widget.shadows,
                                button: buttonsMap[HeaderButtonDetails.more],
                                moreButtons:
                                    [
                                      buttonsMap[HeaderButtonDetails.filters],
                                      buttonsMap[HeaderButtonDetails.sortBy],
                                      buttonsMap[HeaderButtonDetails.style],
                                      buttonsMap[HeaderButtonDetails.favorite],
                                      buttonsMap[HeaderButtonDetails.archive],
                                      buttonsMap[HeaderButtonDetails.sendToTrash],
                                      buttonsMap[HeaderButtonDetails.discardHistory],
                                    ].where((e) => e != null).map((e) => e!).toList(),
                                onSelected: (selected) {
                                  if (selected == HeaderButtonDetails.filters) {
                                    HeaderButtons.filtersPressed(context: context, guiManager: widget.guiManager, updateDb: widget.updateDbFilters);
                                  } else if (selected == HeaderButtonDetails.sortBy) {
                                    widget._sortByPressed(context: context, guiManager: widget.guiManager);
                                  } else if (selected == HeaderButtonDetails.style) {
                                    widget._stylePressed(guiManager: widget.guiManager);
                                  } else if (selected == HeaderButtonDetails.favorite) {
                                    widget._favoritePressed(context: context);
                                  } else if (selected == HeaderButtonDetails.archive) {
                                    widget._archivePressed(context: context);
                                  } else if (selected == HeaderButtonDetails.sendToTrash) {
                                    widget._sendToTrashPressed(context: context);
                                  } else if (selected == HeaderButtonDetails.discardHistory) {
                                    widget._discardHistoryPressed(context: context);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 1.4),
                        ],
                      );
                    },
                  );
                },
              ),
              widget.title != null
                  ? AnimatedScaleText(
                    duration: c.animationDuration,
                    trueText: widget.title!,
                    falseText: '$selectionQuantity selected',
                    condition: selectionQuantity == null,
                    textStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: widget.color ?? Theme.of(context).colorScheme.primary,
                      shadows: widget.shadows,
                    ),
                  )
                  : const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}
