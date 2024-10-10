import 'package:flutter/material.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/tools/color_luminance_comparator.dart';
import 'package:ohnote/tools/datetime_to_str_converter.dart';

class Note {
  Note({
    required this.id,
    required this.text,
    required this.guiManager,
    DateTime? modifDateTime,
    DateTime? creationDateTime,
    this.userOrder = 0,
    bool isCrossedOut = false,
    int numberOfLines = 1,
    Color? color,
    List<int>? labelIds,
    bool favorite = false,
    this.parentId, //Used to set the owner note of the history or draft (parentId in 0 is a new draft)
    this.historyDateTime,
    this.trashDateTime,
    this.archiveDateTime,
  }) {
    var now = DateTime.now();
    this.modifDateTime = modifDateTime ?? now;
    this.creationDateTime = creationDateTime ?? now;
    this.isCrossedOut.value = isCrossedOut;
    this.numberOfLines.value = numberOfLines;
    this.color.value = color;
    this.labelIds = labelIds ?? [];
    this.favorite.value = favorite;
    isChecked.addListener(() {
      if (canRiseIsCheckedListeners) {
        //Remember to call this listeners in MainList after onReorderEnd.
        guiManager.validateIsAllSelected();
        guiManager.setStyleSelectedValues();
      }
    });
  }

  factory Note.fromDbQuery(Map<String, dynamic> map, GuiManager guiManager) {
    int? colorValue = map['color'];
    String? historyDateTime = map['history_date_time'];
    String? trashDateTime = map['trash_date_time'];
    String? archiveDateTime = map['archive_date_time'];
    return Note(
      id: map['id'],
      text: map['text'],
      modifDateTime: DateTime.parse(map['modif_date_time']),
      creationDateTime: DateTime.parse(map['creation_date_time']),
      guiManager: guiManager,
      isCrossedOut: map['is_crossed_out'] == 1,
      numberOfLines: map['number_of_lines'],
      color: colorValue != null ? Color(colorValue) : null,
      labelIds: map['label_ids']?.toString().split(',').map((e) => int.parse(e)).toList(),
      favorite: map['favorite'] == 1,
      parentId: map['parent_id'],
      historyDateTime: historyDateTime != null ? DateTime.parse(historyDateTime) : null,
      trashDateTime: trashDateTime != null ? DateTime.parse(trashDateTime) : null,
      archiveDateTime: archiveDateTime != null ? DateTime.parse(archiveDateTime) : null,
    );
  }

  //Database fields
  int id;
  String text;
  GuiManager guiManager;
  late DateTime modifDateTime;
  late DateTime creationDateTime;
  int userOrder;
  final isCrossedOut = ValueNotifier<bool>(false);
  final numberOfLines = ValueNotifier<int>(1);
  final color = ValueNotifier<Color?>(null);
  final favorite = ValueNotifier<bool>(false);
  int? parentId;
  DateTime? historyDateTime;
  DateTime? trashDateTime;
  DateTime? archiveDateTime;
  List<int> labelIds = [];

  final isChecked = ValueNotifier<bool>(false);
  bool isCheckedBeforeDragging = false;
  bool canRiseIsCheckedListeners = true;
  int slideAnimationState = 0;
  bool performingHero = false;
  double? tileYPosition;

  String get localFormatModifDateTime => modifDateTime.parseToStr(DTToStrFormat.LOCAL);
  String get localFormatCreationDateTime => creationDateTime.parseToStr(DTToStrFormat.LOCAL);
  String? get localFormatHistoryDateTime => historyDateTime?.parseToStr(DTToStrFormat.LOCAL);
  String? get localFormatTrashDateTime => trashDateTime?.parseToStr(DTToStrFormat.LOCAL);
  String? get localFormatArchiveDateTime => archiveDateTime?.parseToStr(DTToStrFormat.LOCAL);

  Duration getTimeLeftInTrash() => trashDateTime != null ? const Duration(days: 30) - DateTime.now().difference(trashDateTime!) : Duration.zero;

  Color foregroundColor(BuildContext context, {Color? defaultColor, Color? inverseColor}) {
    var theme = Theme.of(context);
    defaultColor ??= theme.colorScheme.onSurface;
    inverseColor ??= theme.colorScheme.onPrimary;
    if (color.value != null) {
      if (color.value!.isDark()) {
        return theme.brightness == Brightness.dark ? defaultColor : inverseColor;
      } else {
        return theme.brightness == Brightness.dark ? inverseColor : defaultColor;
      }
    } else {
      return defaultColor;
    }
  }

  String? labelIdsString() => labelIds.isNotEmpty ? labelIds.join(',') : null;

  Note clone() {
    var note = Note(
      id: id,
      text: text,
      guiManager: guiManager,
      modifDateTime: modifDateTime,
      creationDateTime: creationDateTime,
      userOrder: userOrder,
      isCrossedOut: isCrossedOut.value,
      numberOfLines: numberOfLines.value,
      color: color.value,
      favorite: favorite.value,
      labelIds: labelIds,
      parentId: parentId,
      historyDateTime: historyDateTime,
      trashDateTime: trashDateTime,
      archiveDateTime: archiveDateTime,
    );
    note.isChecked.value = isChecked.value;
    note.isCheckedBeforeDragging = isCheckedBeforeDragging;
    note.canRiseIsCheckedListeners = canRiseIsCheckedListeners;
    note.slideAnimationState = slideAnimationState;
    note.performingHero = performingHero;
    note.tileYPosition = tileYPosition;
    return note;
  }

  //Used by jsonEncode in HomeWidgetManager.
  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}
