import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/tools/datetime_to_str_converter.dart';

class Filters {
  Filters({
    this.favorites = false,
    this.from,
    this.to,
    this.text = '',
    List<int>? labelIds,
    List<Color>? colors,
    this.crossedOut = false,
  }) {
    if (labelIds != null) {
      this.labelIds.addAll(labelIds);
    }
    if (colors != null) {
      this.colors.addAll(colors);
    }
  }

  bool favorites;
  DateTime? from;
  DateTime? to;
  String text;
  final List<int> labelIds = [];
  final List<Color> colors = [];
  bool crossedOut;

  static const FAVORITES = 'Favorites'; // ignore: constant_identifier_names
  static const BY_DATE = 'By date'; // ignore: constant_identifier_names
  static const BY_TEXT = 'By text'; // ignore: constant_identifier_names
  static const BY_LABEL = 'By label'; // ignore: constant_identifier_names
  static const BY_COLOR = 'By color'; // ignore: constant_identifier_names
  static const CROSSED_OUT = 'Crossed out'; // ignore: constant_identifier_names

  factory Filters.fromDbQuery(List<Map<String, dynamic>> query) {
    var filters = Filters();
    for (var row in query) {
      var value = row['value'] as String?;
      switch (row['filter']) {
        case FAVORITES:
          filters.favorites = value == true.toString();
          break;
        case BY_DATE:
          if (value != null) {
            var split = value.split('-');
            if (split[0] != null.toString()) {
              filters.from = DateTime.parse(split[0]);
            }
            if (split[1] != null.toString()) {
              filters.to = DateTime.parse(split[1]);
            }
          }
          break;
        case BY_TEXT:
          filters.text = value ?? '';
          break;
        case BY_LABEL:
          var labelIds = value?.split(',').map((e) => int.parse(e));
          if (labelIds != null) {
            filters.labelIds.addAll(labelIds);
          }
          break;
        case BY_COLOR:
          var colors = value?.split(',').map((e) => Color(int.parse(e)));
          if (colors != null) {
            filters.colors.addAll(colors);
          }
          break;
        case CROSSED_OUT:
          filters.crossedOut = value == true.toString();
          break;
      }
    }
    return filters;
  }

  bool hasApplied() => favorites || from != null || to != null || text.isNotEmpty || labelIds.isNotEmpty || colors.isNotEmpty || crossedOut;

  List<String> getAppliedCaptions([bool detailed = false]) {
    var textResult = text.split('\n')[0].replaceAll('\r', '');
    if (textResult.length > 400) {
      textResult = textResult.substring(0, 400);
    }
    return detailed
        ? _addAppliedToList(
            'Filtered by favorites',
            'Filtered by date:'
                '${from != null ? ' from ${from!.dateToStr(DTToStrFormat.LOCALE)}' : ''}'
                '${to != null ? ' to ${to!.dateToStr(DTToStrFormat.LOCALE)}' : ''}',
            'Filtered by text: $textResult',
            'Filtered by labels: ${[
              ...labelIds.where((e) => e > 0).map((id) {
                return AppData.labels.firstWhere((e) => e.id == id).text;
              }),
              labelIds.contains(0) ? 'Without label' : null,
            ].where((e) => e != null).join(', ')}',
            'Filtered by colors',
            'Filtered by crossed out')
        : _addAppliedToList(FAVORITES, BY_DATE, BY_TEXT, BY_LABEL, BY_COLOR, CROSSED_OUT);
  }

  List<T> _addAppliedToList<T>(T ifFavorites, T ifDate, T ifText, T ifLabels, T ifColors, T ifCrossedOut) {
    var list = <T>[];
    if (favorites) {
      list.add(ifFavorites);
    }
    if (from != null || to != null) {
      list.add(ifDate);
    }
    if (text.isNotEmpty) {
      list.add(ifText);
    }
    if (labelIds.isNotEmpty) {
      list.add(ifLabels);
    }
    if (colors.isNotEmpty) {
      list.add(ifColors);
    }
    if (crossedOut) {
      list.add(ifCrossedOut);
    }
    return list;
  }

  void copyFrom(Filters source) {
    favorites = source.favorites;
    from = source.from;
    to = source.to;
    text = source.text;
    labelIds.clear();
    labelIds.addAll(source.labelIds);
    colors.clear();
    colors.addAll(source.colors);
    crossedOut = source.crossedOut;
  }
}
