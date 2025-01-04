import 'package:flutter/material.dart';

extension ColorToInt on Color {
  int toInt() {
    var alpha = (a * 255).toInt().toRadixString(16).padLeft(2, '0');
    var red = (r * 255).toInt().toRadixString(16).padLeft(2, '0');
    var green = (g * 255).toInt().toRadixString(16).padLeft(2, '0');
    var blue = (b * 255).toInt().toRadixString(16).padLeft(2, '0');
    return int.parse('$alpha$red$green$blue', radix: 16);
  }
}
