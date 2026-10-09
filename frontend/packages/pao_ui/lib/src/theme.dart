import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/typography.dart';

/// Builds the Material theme every PAO app uses.
abstract final class PaoTheme {
  /// The light theme for [accent]; Midnight is the default (05-screens.md).
  static ThemeData light({AccentPreset accent = AccentPreset.midnight}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent.primary,
      primary: accent.primary,
      onPrimary: PaoColors.onPrimary,
      primaryContainer: accent.soft,
      onPrimaryContainer: accent.strong,
      secondaryContainer: accent.soft,
      onSecondaryContainer: accent.strong,
      surface: PaoColors.surface,
      onSurface: PaoColors.textPrimary,
      onSurfaceVariant: PaoColors.textSecondary,
      outline: PaoColors.border,
      outlineVariant: PaoColors.border,
      error: PaoColors.danger,
    );
    final text = paoTextTheme();
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(PaoRadius.md),
      borderSide: const BorderSide(color: PaoColors.border),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: PaoColors.canvas,
      textTheme: text,
      fontFamily: PaoFonts.latin,
      fontFamilyFallback: const [PaoFonts.bangla],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [PaoColors(accent)],
      dividerTheme: const DividerThemeData(color: PaoColors.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: PaoColors.canvas,
        foregroundColor: PaoColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaoColors.surface,
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(
          borderSide: BorderSide(color: accent.primary, width: 1.5),
        ),
        errorBorder: field.copyWith(
          borderSide: const BorderSide(color: PaoColors.danger),
        ),
        hintStyle: text.bodyMedium!.copyWith(color: PaoColors.textTertiary),
      ),
    );
  }
}
