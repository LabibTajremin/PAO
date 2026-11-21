import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pao_ui/src/theme_parts.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/typography.dart';

/// Builds the Material theme every PAO app uses.
abstract final class PaoTheme {
  /// The light theme for [accent]; Navy is the default (ADR-0038). [bangla]
  /// sets the Bangla family and metrics; [platform] picks the system font on
  /// iOS and defaults to the running platform.
  static ThemeData light({
    AccentPreset accent = AccentPreset.navy,
    bool bangla = false,
    TargetPlatform? platform,
  }) => _build(PaoColors(accent), bangla: bangla, platform: platform);

  /// The dark (navy-ink) theme; the parameters are as for [light].
  static ThemeData dark({
    AccentPreset accent = AccentPreset.navy,
    bool bangla = false,
    TargetPlatform? platform,
  }) =>
      _build(PaoColors(accent, dark: true), bangla: bangla, platform: platform);

  static ThemeData _build(
    PaoColors c, {
    required bool bangla,
    TargetPlatform? platform,
  }) {
    final p = platform ?? defaultTargetPlatform;
    final text = paoTextTheme(dark: c.dark, bangla: bangla, platform: p);
    final family = bangla ? PaoFonts.banglaOn(p) : PaoFonts.latinOn(p);
    final fallback = bangla ? PaoFonts.latinOn(p) : PaoFonts.banglaOn(p);
    return ThemeData(
      useMaterial3: true,
      platform: p,
      colorScheme: paoColorScheme(c),
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      textTheme: text,
      fontFamily: family,
      fontFamilyFallback: [?fallback],
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
