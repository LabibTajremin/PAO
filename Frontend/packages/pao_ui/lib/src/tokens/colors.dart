import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';

/// PAO colours, the "Navy trust" palette (ADR-0038, `06-update-2026-11.md`
/// §2): a warm ground, white cards, ink text and the active accent. Read them
/// with `context.pao`.
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

  /// Page background: the owner's Ground lifted a step so large areas stay
  /// bright.
  static const canvas = Color(0xFFF6F4EC);

  /// Cards, sheets and bars.
  static const surface = Color(0xFFFFFFFF);

  /// The owner's Ground: section bands, wells and input fills.
  static const field = Color(0xFFF0EEDF);

  /// Hairlines and card borders.
  static const border = Color(0xFFE4E0CF);

  /// Headings and body text: the owner's Ink.
  static const textPrimary = Color(0xFF1C1C1A);

  /// Supporting text.
  static const textSecondary = Color(0xFF56554F);

  /// Hints and inactive icons; still AA so hints stay readable.
  static const textTertiary = Color(0xFF6B6A62);

  /// The owner's Action orange: badges, live dots and highlights. Never for
  /// text or under white labels, where it fails contrast.
  static const highlight = Color(0xFFFE492A);

  /// Filled "urgent" buttons that carry white text.
  static const actionStrong = Color(0xFFD4341A);

  /// Card shadow: navy-tinted, never grey.
  static const cardShadow = [
    BoxShadow(color: Color(0x0F16336F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x1A16336F),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -8,
    ),
  ];

  /// Errors and destructive actions.
  static const danger = Color(0xFFB42318);

  /// Success states such as a completed job.
  static const success = Color(0xFF17672F);

  /// Warnings such as an expiring document.
  static const warning = Color(0xFF8A4F05);

  /// Page background; dark mode is deep navy-ink, never pure black.
  Color get paper => dark ? const Color(0xFF0E1322) : canvas;

  /// Cards and bars.
  Color get card => dark ? const Color(0xFF151B2D) : surface;

  /// Sheets and menus, which sit above cards.
  Color get elevated => dark ? const Color(0xFF1B2338) : surface;

  /// Section bands, filled inputs and skeleton blocks.
  Color get well => dark ? const Color(0xFF1B2338) : field;

  /// The same as [well]; the palette's name for section bands.
  Color get sunken => well;

  /// Hairline borders.
  Color get hairline => dark ? const Color(0xFF263049) : border;

  /// Primary text.
  Color get ink => dark ? const Color(0xFFEEEBDD) : textPrimary;

  /// Secondary text.
  Color get inkMuted => dark ? const Color(0xFFA7AEC2) : textSecondary;

  /// Hints, inactive icons and disabled text.
  Color get inkFaint => dark ? const Color(0xFF8C93A8) : textTertiary;

  /// Badges, live dots and highlights in the owner's Action orange.
  Color get spark => dark ? const Color(0xFFFF7A5E) : highlight;

  /// Orange text, for the rare word that must stand out.
  Color get sparkInk =>
      dark ? const Color(0xFFFF7A5E) : const Color(0xFFC2301A);

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
  /// The [PaoColors] of the nearest theme (light Navy when none is set).
  PaoColors get pao =>
      Theme.of(this).extension<PaoColors>() ??
      const PaoColors(AccentPreset.navy);
}
