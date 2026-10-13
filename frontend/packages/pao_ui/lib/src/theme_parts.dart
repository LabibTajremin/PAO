import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// The Material colour scheme for [c]. Every surface role is pinned to the
/// paper palette so Material defaults never fall back to seeded lavender.
ColorScheme paoColorScheme(PaoColors c) => ColorScheme.fromSeed(
  seedColor: c.accent.primary,
  brightness: c.dark ? Brightness.dark : Brightness.light,
  primary: c.action,
  onPrimary: c.onAction,
  primaryContainer: c.selectedFill,
  onPrimaryContainer: c.selectedInk,
  secondaryContainer: c.selectedFill,
  onSecondaryContainer: c.selectedInk,
  surface: c.card,
  onSurface: c.ink,
  onSurfaceVariant: c.inkMuted,
  surfaceContainerLowest: c.card,
  surfaceContainerLow: c.card,
  surfaceContainer: c.card,
  surfaceContainerHigh: c.card,
  surfaceContainerHighest: c.well,
  outline: c.hairline,
  outlineVariant: c.hairline,
  error: c.dangerInk,
);

/// Filled warm inputs with no resting border; focus draws the accent.
InputDecorationTheme paoInputTheme(PaoColors c, TextTheme text) {
  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(PaoRadius.md),
    borderSide: BorderSide(color: c.well),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: c.well,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PaoSpace.lg,
      vertical: PaoSpace.md + 2,
    ),
    border: field,
    enabledBorder: field,
    focusedBorder: field.copyWith(
      borderSide: BorderSide(color: c.action, width: 1.6),
    ),
    errorBorder: field.copyWith(borderSide: BorderSide(color: c.dangerInk)),
    focusedErrorBorder: field.copyWith(
      borderSide: BorderSide(color: c.dangerInk, width: 1.6),
    ),
    hintStyle: text.bodyMedium!.copyWith(color: c.inkFaint),
    errorStyle: text.bodySmall!.copyWith(color: c.dangerInk),
  );
}

/// Flat leaf-shaped cards with a hairline instead of a shadow.
CardThemeData paoCardTheme(PaoColors c) => CardThemeData(
  color: c.card,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: PaoShape.leaf,
    side: BorderSide(color: c.hairline),
  ),
);

/// Leaf-shaped dialogs on the card colour.
DialogThemeData paoDialogTheme(PaoColors c) => DialogThemeData(
  backgroundColor: c.card,
  surfaceTintColor: Colors.transparent,
  shape: const RoundedRectangleBorder(borderRadius: PaoShape.leaf),
);

/// Ink snack bars; they keep Material's fixed placement so nothing they used
/// to leave uncovered gets hidden.
SnackBarThemeData paoSnackBarTheme(PaoColors c, TextTheme text) =>
    SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.paper),
      actionTextColor: c.dark ? c.accent.primary : c.accent.soft,
    );
