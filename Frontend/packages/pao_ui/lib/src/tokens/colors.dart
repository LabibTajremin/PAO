import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';

/// PAO colours in the Nakshi direction (ADR 0033): warm paper surfaces, deep
/// ink text and the accent from Figma `Accent`. Read them with `context.pao`.
///
/// The static constants are the light-mode values and stay for app code that
/// predates dark mode; widgets read the mode-aware getters instead.
@immutable
class PaoColors extends ThemeExtension<PaoColors> {
  /// Creates the colour set for [accent]; [dark] selects the ink palette.
  const PaoColors(this.accent, {this.dark = false});

  /// The active accent.
  final AccentPreset accent;

  /// Whether this is the dark (deep ink) palette.
  final bool dark;

  /// Text and icons on [AccentPreset.primary]; white in every mode.
  static const onPrimary = Color(0xFFFFFFFF);

  /// Page background: warm paper.
  static const canvas = Color(0xFFFAF6EF);

  /// Cards and sheets, a shade lighter than the paper.
  static const surface = Color(0xFFFFFDF8);

  /// Filled inputs and wells, a shade deeper than the paper.
  static const field = Color(0xFFF2ECE2);

  /// Hairlines and card borders.
  static const border = Color(0xFFE6DCCB);

  /// Headings and body text: deep ink.
  static const textPrimary = Color(0xFF1F1B16);

  /// Supporting text: warm grey.
  static const textSecondary = Color(0xFF655C52);

  /// Hints and disabled text; still AA on paper so hints stay readable.
  static const textTertiary = Color(0xFF6F665A);

  /// Errors and destructive actions.
  static const danger = Color(0xFFB42318);

  /// Success states such as a completed job.
  static const success = Color(0xFF17672F);

  /// Warnings such as an expiring document.
  static const warning = Color(0xFF8A4F05);

  /// Page background.
  Color get paper => dark ? const Color(0xFF16130F) : canvas;

  /// Cards, sheets and bars.
  Color get card => dark ? const Color(0xFF201B16) : surface;

  /// Filled inputs and skeleton blocks.
  Color get well => dark ? const Color(0xFF2A241D) : field;

  /// Hairline borders.
  Color get hairline => dark ? const Color(0xFF3A3229) : border;

  /// Primary text.
  Color get ink => dark ? const Color(0xFFF3ECE0) : textPrimary;

  /// Secondary text.
  Color get inkMuted => dark ? const Color(0xFFBDB2A3) : textSecondary;

  /// Hints, inactive icons and disabled text.
  Color get inkFaint => dark ? const Color(0xFFA0958A) : textTertiary;

  /// Fill of primary actions and accent-coloured text or icons. Dark mode
  /// uses the light soft tone because the accents are too dark on ink.
  Color get action => dark ? accent.soft : accent.primary;

  /// Text and icons on [action].
  Color get onAction => dark ? accent.deep : onPrimary;

  /// Background of selected chips, segments and soft buttons.
  Color get selectedFill => dark ? accent.deep : accent.soft;

  /// Text on [selectedFill].
  Color get selectedInk => dark ? accent.soft : accent.strong;

  /// Icon tiles and highlighted cards.
  Color get tintFill => dark ? accent.deep : accent.tint;

  /// The kantha stitch: the accent at low opacity.
  Color get stitch => action.withValues(alpha: 0.5);

  /// Error text and icons.
  Color get dangerInk => dark ? const Color(0xFFF97066) : danger;

  /// Success text and icons.
  Color get successInk => dark ? const Color(0xFF5CC489) : success;

  /// Warning text and icons.
  Color get warningInk => dark ? const Color(0xFFF0B35A) : warning;

  @override
  PaoColors copyWith({AccentPreset? accent, bool? dark}) =>
      PaoColors(accent ?? this.accent, dark: dark ?? this.dark);

  @override
  PaoColors lerp(PaoColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Shortcut to the PAO colours of the current theme.
extension PaoColorsContext on BuildContext {
  /// The [PaoColors] of the nearest theme (light Midnight when none is set).
  PaoColors get pao =>
      Theme.of(this).extension<PaoColors>() ??
      const PaoColors(AccentPreset.midnight);
}
