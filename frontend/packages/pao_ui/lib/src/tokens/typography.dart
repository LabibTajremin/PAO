import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';

/// Plus Jakarta Sans for Latin text, with Hind Siliguri for Bangla and ৳.
abstract final class PaoFonts {
  /// Latin family bundled with `pao_ui`.
  static const latin = 'packages/pao_ui/PlusJakartaSans';

  /// Bangla family bundled with `pao_ui`.
  static const bangla = 'packages/pao_ui/HindSiliguri';
}

/// The PAO type scale mapped onto Material roles.
TextTheme paoTextTheme() {
  TextStyle style(double size, FontWeight weight, [double height = 1.3]) =>
      TextStyle(
        fontFamily: PaoFonts.latin,
        fontFamilyFallback: const [PaoFonts.bangla],
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: PaoColors.textPrimary,
      );
  return TextTheme(
    displaySmall: style(28, FontWeight.w700, 1.2),
    headlineSmall: style(22, FontWeight.w700, 1.25),
    titleLarge: style(18, FontWeight.w700),
    titleMedium: style(16, FontWeight.w600),
    titleSmall: style(14, FontWeight.w600),
    bodyLarge: style(15, FontWeight.w400, 1.45),
    bodyMedium: style(14, FontWeight.w400, 1.45),
    bodySmall: style(
      12,
      FontWeight.w500,
      1.4,
    ).copyWith(color: PaoColors.textSecondary),
    labelLarge: style(15, FontWeight.w600),
    labelMedium: style(13, FontWeight.w600),
    labelSmall: style(11, FontWeight.w600),
  );
}
