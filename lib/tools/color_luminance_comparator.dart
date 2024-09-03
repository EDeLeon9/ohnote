import 'dart:ui';

extension ColorLuminanceComparator on Color {
  bool isDark() => computeLuminance() < 0.3;
}
