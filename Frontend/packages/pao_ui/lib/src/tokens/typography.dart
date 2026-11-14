import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';

/// Fraunces for headings, Plus Jakarta Sans for body and UI text, and Noto
/// Sans Bengali for Bangla and ৳: the fallback in English, the main family in
/// Bangla (see [paoTextTheme]).
abstract final class PaoFonts {
  /// Latin UI family bundled with `pao_ui`.
  static const latin = 'packages/pao_ui/PlusJakartaSans';

  /// Display serif bundled with `pao_ui`.
  static const display = 'packages/pao_ui/Fraunces';

  /// Bangla family bundled with `pao_ui`.
  static const bangla = 'packages/pao_ui/NotoSansBengali';
}

/// Bangla sizes and line heights against the Latin scale. Bengali letters
/// carry vowel signs above and below the line, so at the Latin size and
/// height they read small and the tallest marks were clipped.
abstract final class PaoBanglaScale {
  /// Font size factor.
  static const size = 1.12;

  /// Added to the line height factor.
  static const height = 0.3;
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

/// A style in the body family; in [bangla] Noto Sans Bengali leads at the
/// larger Bangla size and height, with Plus Jakarta Sans for Latin text.
TextStyle paoBodyStyle(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.35,
  bool bangla = false,
}) => TextStyle(
  fontFamily: bangla ? PaoFonts.bangla : PaoFonts.latin,
  fontFamilyFallback: [if (bangla) PaoFonts.latin else PaoFonts.bangla],
  fontSize: bangla ? size * PaoBanglaScale.size : size,
  fontWeight: weight,
  // Both families are variable; the axis makes the weight hold everywhere.
  fontVariations: [FontVariation('wght', weight.value.toDouble())],
  height: bangla ? height + PaoBanglaScale.height : height,
  color: color,
);

/// The PAO type scale mapped onto Material roles; [dark] picks ink colours
/// for the dark palette and [bangla] the Bangla family and metrics. Headings
/// stay in Fraunces in English; in Bangla they are bold Noto, which has the
/// glyphs Fraunces lacks.
TextTheme paoTextTheme({bool dark = false, bool bangla = false}) {
  final c = PaoColors(AccentPreset.midnight, dark: dark);
  TextStyle style(double size, FontWeight weight, [double height = 1.35]) =>
      paoBodyStyle(size, weight, c.ink, height: height, bangla: bangla);
  TextStyle heading(double size, double height) => bangla
      ? style(size, FontWeight.w700, height)
      : paoDisplayStyle(size, c.ink).copyWith(height: height);
  return TextTheme(
    displaySmall: heading(30, 1.15),
    headlineSmall: heading(24, 1.2),
    titleLarge: heading(20, 1.25),
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
