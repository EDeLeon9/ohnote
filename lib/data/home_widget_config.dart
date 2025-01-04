import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/tools/datetime_to_str_converter.dart';

class HomeWidgetConfig {
  HomeWidgetConfig({
    required this.id,
    this.title = '',
    this.theme = AppThemeBrightness.systemDefault,
    this.opacity = 100,
    this.creationDateTime,
    Filters? filters,
  }) {
    if (filters != null) {
      notesManager.filters.value = filters;
    }
  }

  final int id;
  String title;
  AppThemeBrightness theme;
  int opacity;
  DateTime? creationDateTime;
  final notesManager = GuiManager(
    sortComparison: (a, b) => a.userOrder.compareTo(b.userOrder),
    getComparisonDateTime: (note) => note.modifDateTime,
  );

  void copyFrom(HomeWidgetConfig source) {
    title = source.title;
    theme = source.theme;
    opacity = source.opacity;
    notesManager.filters.value.copyFrom(source.notesManager.filters.value);
    notesManager.allList = List.of(source.notesManager.allList);
    notesManager.displayList.value = source.notesManager.displayList.value != null ? List.of(source.notesManager.displayList.value!) : null;
  }

  //Used by jsonEncode in HomeWidgetManager.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'theme': theme.caption,
        'opacity': opacity,
        'creation_datetime': creationDateTime!.toStr(DTToStrFormat.DATABASE),
        'filters': notesManager.filters.value.getAppliedCaptions(),
      };
}
