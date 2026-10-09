import 'package:flutter/material.dart';

/// Builds the Material themes used by every PAO app.
abstract final class PaoTheme {
  /// The Midnight accent, PAO's default primary colour (docs/build/05-screens.md).
  static const Color midnight = Color(0xFF1F3A6E);

  /// The light theme seeded from the Midnight accent.
  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: midnight, primary: midnight),
    useMaterial3: true,
  );
}
