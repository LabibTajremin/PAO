import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';

/// Neutral grotesque type (ADR-0038): the system font on iOS (SF Pro, and
/// Kohinoor Bangla for Bangla), and the bundled Inter and Noto Sans Bengali
/// elsewhere, because SF Pro and Helvetica may not ship inside an Android or
/// web app.
abstract final class PaoFonts {
  /// Latin family bundled with `pao_ui`.
  static const latin = 'packages/pao_ui/Inter';

  /// Bangla family bundled with `pao_ui`.
  static const bangla = 'packages/pao_ui/NotoSansBengali';

  /// The Latin family on [platform]; null means the system font.
  static String? latinOn(TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? null : latin;

  /// The Bangla family on [platform]; null means the system font.
  static String? banglaOn(TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? null : bangla;
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

/// A style in the PAO family; in [bangla] the Bangla family leads at the
/// larger Bangla size and height, with the Latin family for Latin text.
TextStyle paoBodyStyle(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.4,
  bool bangla = false,
  TargetPlatform? platform,
}) {
  final p = platform ?? defaultTargetPlatform;
  final family = bangla ? PaoFonts.banglaOn(p) : PaoFonts.latinOn(p);
  final fallback = bangla ? PaoFonts.latinOn(p) : PaoFonts.banglaOn(p);
  return TextStyle(
    fontFamily: family,
    fontFamilyFallback: [?fallback],
    fontSize: bangla ? size * PaoBanglaScale.size : size,
    fontWeight: weight,
    // The bundled families are variable; the axis makes the weight hold on
    // every engine. The system font takes the weight as it is.
    fontVariations: [
      if (family != null) FontVariation('wght', weight.value.toDouble()),
    ],
    height: bangla ? height + PaoBanglaScale.height : height,
    color: color,
  );
}

/// A heading: the body family, heavier and a little tighter.
TextStyle paoHeadingStyle(
  double size,
  Color color, {
  double height = 1.25,
  bool bangla = false,
  TargetPlatform? platform,
}) => paoBodyStyle(
  size,
  FontWeight.w700,
  color,
  height: height,
  bangla: bangla,
  platform: platform,
).copyWith(letterSpacing: bangla ? 0 : -0.2);

/// The one PAO type scale (display 28, title 22, headline 18, body 16,
/// label 14, caption 12) mapped onto Material roles; [dark] picks ink colours
/// and [bangla] the Bangla family and metrics.
TextTheme paoTextTheme({
  bool dark = false,
  bool bangla = false,
  TargetPlatform? platform,
}) {
  final c = PaoColors(AccentPreset.navy, dark: dark);
  TextStyle style(double size, FontWeight weight, [double height = 1.4]) =>
      paoBodyStyle(
        size,
        weight,
        c.ink,
        height: height,
        bangla: bangla,
        platform: platform,
      );
  TextStyle heading(double size, double height) => paoHeadingStyle(
    size,
    c.ink,
    height: height,
    bangla: bangla,
    platform: platform,
  );
  return TextTheme(
    displaySmall: heading(28, 34 / 28),
    headlineSmall: heading(22, 1.27),
    titleLarge: heading(18, 1.33).copyWith(fontWeight: FontWeight.w600),
    titleMedium: style(16, FontWeight.w600),
    titleSmall: style(14, FontWeight.w600),
    bodyLarge: style(16, FontWeight.w400, 1.5),
    bodyMedium: style(16, FontWeight.w400, 1.45),
    bodySmall: style(12, FontWeight.w500).copyWith(color: c.inkMuted),
    labelLarge: style(14, FontWeight.w600),
    labelMedium: style(12, FontWeight.w600),
    labelSmall: style(12, FontWeight.w500),
  );
}
