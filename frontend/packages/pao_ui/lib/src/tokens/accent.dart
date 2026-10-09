import 'dart:ui';

/// The ten accent modes of the Figma `Accent` collection (05-screens.md).
/// Changing the accent re-themes every component.
enum AccentPreset {
  /// PAO's default.
  midnight(
    Color(0xFFF3F5FA),
    Color(0xFFE2E7F2),
    Color(0xFF1F3A6E),
    Color(0xFF162B52),
    Color(0xFF0D1B36),
  ),

  /// Near-black.
  onyx(
    Color(0xFFF5F5F6),
    Color(0xFFE6E6E9),
    Color(0xFF1C1C21),
    Color(0xFF0E0E12),
    Color(0xFF0A0A0C),
  ),

  /// Warm gold.
  champagne(
    Color(0xFFFBF7EF),
    Color(0xFFF2E8D5),
    Color(0xFF8F6420),
    Color(0xFF6E4C17),
    Color(0xFF2E2108),
  ),

  /// Deep red.
  merlot(
    Color(0xFFFBF2F4),
    Color(0xFFF4E1E7),
    Color(0xFF8A1C3F),
    Color(0xFF69142F),
    Color(0xFF330818),
  ),

  /// Teal.
  petrol(
    Color(0xFFEFF8F9),
    Color(0xFFD7ECEF),
    Color(0xFF0B5F6B),
    Color(0xFF084852),
    Color(0xFF042A30),
  ),

  /// Bright blue.
  sapphire(
    Color(0xFFF2F5FC),
    Color(0xFFDFE7F7),
    Color(0xFF2350A8),
    Color(0xFF1A3D82),
    Color(0xFF0C1F45),
  ),

  /// Purple.
  plum(
    Color(0xFFF8F3FA),
    Color(0xFFEEE2F2),
    Color(0xFF5E2A6E),
    Color(0xFF472054),
    Color(0xFF240F2C),
  ),

  /// Burnt orange.
  terracotta(
    Color(0xFFFCF5F2),
    Color(0xFFF6E3DB),
    Color(0xFFA4472C),
    Color(0xFF803620),
    Color(0xFF3A170D),
  ),

  /// Brown.
  espresso(
    Color(0xFFF8F5F2),
    Color(0xFFEEE5DE),
    Color(0xFF5C3D2E),
    Color(0xFF462E22),
    Color(0xFF221610),
  ),

  /// Dusty pink.
  rosewood(
    Color(0xFFFBF4F6),
    Color(0xFFF4E2E8),
    Color(0xFF9E4A66),
    Color(0xFF7B384F),
    Color(0xFF381521),
  );

  AccentPreset(this.tint, this.soft, this.primary, this.strong, this.deep);

  /// Icon tiles and highlighted cards.
  final Color tint;

  /// Selected chips and the active-tab pill.
  final Color soft;

  /// Buttons, active tabs and links.
  final Color primary;

  /// Text on soft and tint surfaces.
  final Color strong;

  /// Hero banners and dark headers.
  final Color deep;
}
