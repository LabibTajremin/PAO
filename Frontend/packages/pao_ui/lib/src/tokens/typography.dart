import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';

/// Fraunces for headings, Plus Jakarta Sans for body and UI text, and Hind
/// Siliguri as the fallback of both so Bangla and ৳ always render.
abstract final class PaoFonts {
  /// Latin UI family bundled with `pao_ui`.
  static const latin = 'packages/pao_ui/PlusJakartaSans';

  /// Display serif bundled with `pao_ui`.
  static const display = 'packages/pao_ui/Fraunces';

  /// Bangla family bundled with `pao_ui`.
  static const bangla = 'packages/pao_ui/HindSiliguri';
}

/// A Fraunces style. Variable fonts ignore [FontWeight] on some engines, so
/// the axes are set explicitly; `opsz` follows the size for crisp headings
/// and `SOFT` rounds the serifs a little to match the leaf corners.
TextStyle paoDisplayStyle(double size, Color color) => TextStyle(
  fontFamily: PaoFonts.display,
  fontFamilyFallback: const [PaoFonts.bangla],
  fontSize: size,
  fontWeight: FontWeight.w600,
  fontVariations: [
    const FontVariation('wght', 600),
    FontVariation('opsz', size),
    const FontVariation('SOFT', 50),
  ],
  height: 1.2,
  letterSpacing: -0.2,
  color: color,
);

/// The PAO type scale mapped onto Material roles; [dark] picks ink colours
/// for the dark palette.
TextTheme paoTextTheme({bool dark = false}) {
  final c = PaoColors(AccentPreset.midnight, dark: dark);
  TextStyle style(double size, FontWeight weight, [double height = 1.35]) =>
      TextStyle(
        fontFamily: PaoFonts.latin,
        fontFamilyFallback: const [PaoFonts.bangla],
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: c.ink,
      );
  return TextTheme(
    displaySmall: paoDisplayStyle(30, c.ink).copyWith(height: 1.15),
    headlineSmall: paoDisplayStyle(24, c.ink),
    titleLarge: paoDisplayStyle(20, c.ink).copyWith(height: 1.25),
    titleMedium: style(16, FontWeight.w600),
    titleSmall: style(14, FontWeight.w600),
    bodyLarge: style(15, FontWeight.w400, 1.55),
    bodyMedium: style(14, FontWeight.w400, 1.5),
    bodySmall: style(12, FontWeight.w500, 1.45).copyWith(color: c.inkMuted),
    labelLarge: style(15, FontWeight.w600).copyWith(letterSpacing: 0.2),
    labelMedium: style(13, FontWeight.w600).copyWith(letterSpacing: 0.1),
    labelSmall: style(11, FontWeight.w600).copyWith(letterSpacing: 0.3),
  );
}
