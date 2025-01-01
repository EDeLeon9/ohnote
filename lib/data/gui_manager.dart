import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/tools/boxed_value.dart';
import 'package:ohnote/tools/words_searcher.dart';
import 'package:ohnote/tools/valuenotifier_plus.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_toast.dart' as t;

class GuiManager {
  GuiManager({required this.sortComparison, required this.getComparisonDateTime}) {
    selectionQuantity.addListener(() {
      if (selectionQuantity.value == null) {
        isManualSelection = false;
        stylePanelOpened.value = false;
        if (displayList.value?.any((e) => e.isChecked.value) == true) {
          setIsCheckedToAll(false);
        }
      }
    });
    filters.addListener(requestUpdateDisplayList);
  }

  List<Note> allList = [];
  final displayList = ValueNotifierPlus<List<Note>?>(null);
  final filters = ValueNotifierPlus<Filters>(Filters());
  final selectionQuantity = ValueNotifier<int?>(null);
  final isAllSelected = ValueNotifier<bool>(false);
  final stylePanelOpened = ValueNotifier<bool>(false);
  List<Color> styleColors = [];
  final styleSelectedColor = ValueNotifier<Color?>(null);
  final styleSelectedNumberOfLines = ValueNotifier<int>(1);
  final showSearchText = ValueNotifier<bool>(false);
  final searchTextFocusNode = FocusNode();
  final int Function(Note a, Note b) sortComparison;
  DateTime Function(Note note) getComparisonDateTime;
  BoxedValue<bool>? _cancelFiltering;

  bool _isManualSelection = false;
  bool get isManualSelection => _isManualSelection;
  set isManualSelection(bool value) {
    _isManualSelection = value;
    if (selectionQuantity.value == null && value) {
      selectionQuantity.value = 0;
    }
  }

  List<Note> getSelectedNotes() {
    return displayList.value?.where((e) => e.isChecked.value).toList() ?? <Note>[];
  }

  void setIsCheckedToAll(bool value) {
    if (displayList.value != null) {
      for (var note in displayList.value!.where((e) => e.isChecked.value != value)) {
        note.canRiseIsCheckedListeners = false;
        note.isChecked.value = value;
        note.canRiseIsCheckedListeners = true;
      }
      isAllSelected.value = value;
      setStyleSelectedValues();
    }
  }

  void validateIsAllSelected() {
    isAllSelected.value = displayList.value?.every((e) => e.isChecked.value) == true;
  }

  void setStyleSelectedValues() {
    var selectedNotes = getSelectedNotes();
    if (selectedNotes.map((e) => e.numberOfLines.value).toSet().length == 1) {
      styleSelectedNumberOfLines.value = selectedNotes.first.numberOfLines.value;
    }
    styleSelectedColor.value = selectedNotes.map((e) => e.color.value).toSet().length == 1 ? selectedNotes.first.color.value : null;
  }

  void setSelectionQuantity() {
    selectionQuantity.value = getSelectedNotes().length;
  }

  void updateStyleColors() {
    styleColors = allList.where((e) => e.color.value != null).map((e) => e.color.value!).toSet().toList();
  }

  Future<void> requestUpdateDisplayList() {
    _cancelFiltering?.value = true;
    _cancelFiltering = BoxedValue(false);
    return _filterList(_cancelFiltering!);
  }

  Future<void> _filterList(BoxedValue<bool> cancelFiltering) async {
    if (selectionQuantity.value != null) {
      selectionQuantity.value = null;
    }
    if (filters.value.hasApplied()) {
      List<Note> filteredList = [];
      var stopwatch = Stopwatch();
      stopwatch.start();
      //Notes can be empty when editing and slided in the NoteEditPage PageView.
      for (var note in allList.where((e) => e.text.trim().isNotEmpty).toList()) {
        if (cancelFiltering.value) {
          break;
        }
        if (noteIsInFilter(note)) {
          filteredList.add(note);
        }
        if (stopwatch.elapsedMilliseconds >= 10) {
          displayList.value = null; //Enables wait animation.
          await Future.delayed(const Duration(milliseconds: 1));
          stopwatch.reset();
        }
      }
      stopwatch.stop();
      if (!cancelFiltering.value) {
        displayList.value = filteredList;
      }
    } else {
      //Notes can be empty when editing and slided in the NoteEditPage PageView.
      displayList.value = List.of(allList.where((e) => e.text.trim().isNotEmpty).toList());
    }
  }

  bool noteIsInFilter(Note note) {
    WordsSearcher? wordsSearcher;
    if (filters.value.text.isNotEmpty) {
      wordsSearcher = WordsSearcher(filters.value.text);
    }
    DateTime noteDateTime = getComparisonDateTime(note);
    return (!filters.value.favorites || note.favorite.value) &&
        (!filters.value.crossedOut || note.isCrossedOut.value) &&
        (filters.value.from == null || !noteDateTime.isBefore(filters.value.from!)) &&
        (filters.value.to == null || noteDateTime.isBefore(filters.value.to!.add(const Duration(days: 1)))) &&
        (filters.value.labelIds.isEmpty || filters.value.labelIds.any((e) => note.labelIds.contains(e) || (e == 0 && note.labelIds.isEmpty))) &&
        (filters.value.colors.isEmpty || (filters.value.colors.contains(note.color.value ?? Colors.transparent))) &&
        (filters.value.text == '' || wordsSearcher!.searchIn(note.text));
  }

  Future<void> startSlideAnimation({
    required BuildContext context,
    required int slideAnimationState,
    required void Function(List<Note> selectedNotes) afterAnimationStateAction,
    required String successMessage,
    Future<bool> Function()? confirmationDialog,
    String itemsNoun = 'notes',
    List<Note>? notesToUse,
  }) async {
    if (notesToUse != null || selectionQuantity.value != null) {
      List<Note> selectedNotes;
      if (notesToUse == null || notesToUse.isEmpty) {
        selectedNotes = getSelectedNotes();
        if (selectedNotes.isEmpty) {
          t.showCustomToast('No $itemsNoun selected.', context);
          return;
        }
      } else {
        selectedNotes = notesToUse;
      }
      //Every note must have slideAnimationState == 0. This ensures not tu run again this code while other notes are being slided.
      if (selectedNotes.every((e) => e.slideAnimationState == 0) && (await confirmationDialog?.call() ?? true)) {
        for (var note in selectedNotes) {
          note.slideAnimationState = slideAnimationState;
        }
        //Performs animations of tiles that validates note.slideAnimationState.
        displayList.notifyListeners();
        //Waits for slide and shrink animations before removing the notes from list.
        await Future.delayed(Duration(milliseconds: c.animationDuration.inMilliseconds * 2));
        afterAnimationStateAction(selectedNotes);
        //Updates the list before setting selectionQuantity to null.
        displayList.notifyListeners();
        //Restores the note values.
        for (var note in selectedNotes) {
          note.slideAnimationState = 0;
          note.isChecked.value = false;
        }
        //Wait required to make the animations using selectionQuantity and isChecked to be performed correctly.
        await Future.delayed(const Duration(milliseconds: 100));
        if (!stylePanelOpened.value) {
          selectionQuantity.value = null;
        }
        //Set final values.
        setStyleSelectedValues();
        //Shows message.
        if (context.mounted) {
          t.showCustomToast(successMessage, context);
        }
      }
    } else {
      isManualSelection = true;
      t.showCustomToast('First select the $itemsNoun.', context);
    }
  }
}
