import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';

/// PAO colours: the accent from Figma `Accent` and neutrals and status colours
/// from `Base`. Read them with `context.pao`.
@immutable
class PaoColors extends ThemeExtension<PaoColors> {
  /// Creates the colour set for [accent].
  const PaoColors(this.accent);

  /// The active accent.
  final AccentPreset accent;

  /// Text and icons on [AccentPreset.primary]; white in every mode.
  static const onPrimary = Color(0xFFFFFFFF);

  /// Page background.
  static const canvas = Color(0xFFF5F6F8);

  /// Cards and sheets.
  static const surface = Color(0xFFFFFFFF);

  /// Hairlines and card borders.
  static const border = Color(0xFFE5E7EB);

  /// Headings and body text.
  static const textPrimary = Color(0xFF0F172A);

  /// Supporting text.
  static const textSecondary = Color(0xFF475569);

  /// Hints and disabled text.
  static const textTertiary = Color(0xFF94A3B8);

  /// Errors and destructive actions.
  static const danger = Color(0xFFDC2626);

  /// Success states such as a completed job.
  static const success = Color(0xFF16A34A);

  /// Warnings such as an expiring document.
  static const warning = Color(0xFFD97706);

  @override
  PaoColors copyWith({AccentPreset? accent}) =>
      PaoColors(accent ?? this.accent);

  @override
  PaoColors lerp(PaoColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Shortcut to the PAO colours of the current theme.
extension PaoColorsContext on BuildContext {
  /// The [PaoColors] of the nearest theme (Midnight when none is set).
  PaoColors get pao =>
      Theme.of(this).extension<PaoColors>() ??
      const PaoColors(AccentPreset.midnight);
}
