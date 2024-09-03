import 'package:flutter/material.dart';

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

  List<String> getAppliedCaptions() {
    List<String> captions = [];
    if (favorites) {
      captions.add(FAVORITES);
    }
    if (from != null || to != null) {
      captions.add(BY_DATE);
    }
    if (text != '') {
      captions.add(BY_TEXT);
    }
    if (labelIds.isNotEmpty) {
      captions.add(BY_LABEL);
    }
    if (colors.isNotEmpty) {
      captions.add(BY_COLOR);
    }
    if (crossedOut) {
      captions.add(CROSSED_OUT);
    }
    return captions;
  }

  bool hasApplied() => favorites || from != null || to != null || text != '' || labelIds.isNotEmpty || colors.isNotEmpty || crossedOut;

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
