import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// extension CustomColors on ThemeData {
//   ThemeData copyWithOnSurfaceVariant(Color? Function(ColorScheme colorScheme) colorBuilder) {
//     return copyWith(colorScheme: colorScheme.copyWith(onSurfaceVariant: colorBuilder(colorScheme)));
//   }
// }

enum AppThemeBrightness {
  systemDefault('System default'),
  light('Light theme'),
  dark('Dark theme');

  final String caption;
  const AppThemeBrightness(this.caption);
}

class AppTheme {
  AppTheme._();

  static final current = AppTheme._();

  late final ThemeData lightTheme = _createThemeData(false);
  late final ThemeData darkTheme = _createThemeData(true);

  ThemeData _createThemeData(bool isDark) {
    var colorScheme = isDark ? _darkColorScheme : _lightColorScheme;
    var theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        elevation: 2.0,
        toolbarHeight: 55.0,
        color: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.primary,
        shadowColor: colorScheme.shadow,
        titleTextStyle: TextStyle(fontSize: 26.0, color: colorScheme.primary),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarDividerColor: colorScheme.surface,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark, //Navigation buttons.
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0.0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      splashColor: colorScheme.primary.withValues(alpha: 0.2),
    );
  }

  final appIconColor = Color(0xFF132A38);

  final _lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006782),
    onPrimary: Color(0xFFFCF8F4),
    primaryContainer: Color(0xFF006782),
    onPrimaryContainer: Color(0xFFFCF8F4),
    secondary: Color(0xFF3E5C6B),
    onSecondary: Color(0xFFFCF8F4),
    secondaryContainer: Color(0xFFA8C8D2),
    onSecondaryContainer: Color(0xFF081E26),
    tertiary: Color(0xFF593C22),
    onTertiary: Color(0xFFF1DEC8),
    tertiaryContainer: Color(0xFFFCF8F4),
    onTertiaryContainer: Color(0xFF301400),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF7EDE3),
    onSurface: Color(0xFF292929),
    surfaceContainerHighest: Color(0xFFD9E1E3),
    onSurfaceVariant: Color(0xFF292929),
    outline: Color(0xFFB4B4B4),
    onInverseSurface: Color(0xFFFFF0CB),
    inverseSurface: Color(0xFF554100),
    inversePrimary: Color(0xFFD0F2FF),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFFFCF8F4),
    outlineVariant: Color(0xFFC0C8CC),
    scrim: Color(0xFF000000),
  );

  final _darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD0F2FF),
    onPrimary: Color(0xFF010F13),
    primaryContainer: Color(0xFFD0F2FF),
    onPrimaryContainer: Color(0xFF010F13),
    secondary: Color(0xFFB4CAD5),
    onSecondary: Color(0xFF010F13),
    secondaryContainer: Color(0xFF46646F),
    onSecondaryContainer: Color(0xFFCFE6F2),
    tertiary: Color(0xFFFFB785),
    onTertiary: Color(0xFF010F13),
    tertiaryContainer: Color(0xFF323232),
    onTertiaryContainer: Color(0xFFFFDCC6),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFF191F21),
    onSurface: Color(0xFFEAF1F3),
    surfaceContainerHighest: Color(0xFF323232),
    onSurfaceVariant: Color(0xFFDCE4E8),
    outline: Color(0xFF5F5F5F),
    onInverseSurface: Color(0xFF231A00),
    inverseSurface: Color(0xFFEBEBEB),
    inversePrimary: Color(0xFF006782),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF010F13),
    outlineVariant: Color(0xFF40484C),
    scrim: Color(0xFF000000),
  );
}
