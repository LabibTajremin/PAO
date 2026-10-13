import 'package:flutter/material.dart';
import 'package:pao_ui/src/theme_parts.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/typography.dart';

/// Builds the Material theme every PAO app uses.
abstract final class PaoTheme {
  /// The light (paper) theme for [accent]; Midnight is the default
  /// (05-screens.md).
  static ThemeData light({AccentPreset accent = AccentPreset.midnight}) =>
      _build(PaoColors(accent));

  /// The dark (deep ink) theme for [accent].
  static ThemeData dark({AccentPreset accent = AccentPreset.midnight}) =>
      _build(PaoColors(accent, dark: true));

  static ThemeData _build(PaoColors c) {
    final text = paoTextTheme(dark: c.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: paoColorScheme(c),
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      textTheme: text,
      fontFamily: PaoFonts.latin,
      fontFamilyFallback: const [PaoFonts.bangla],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.hairline, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      inputDecorationTheme: paoInputTheme(c, text),
      cardTheme: paoCardTheme(c),
      dialogTheme: paoDialogTheme(c),
      snackBarTheme: paoSnackBarTheme(c, text),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.card),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.action),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.action),
    );
  }
}
