/// Spacing on a 4-point scale.
abstract final class PaoSpace {
  /// 4 dp.
  static const double xs = 4;

  /// 8 dp.
  static const double sm = 8;

  /// 12 dp.
  static const double md = 12;

  /// 16 dp, the default page gutter.
  static const double lg = 16;

  /// 20 dp.
  static const double xl = 20;

  /// 24 dp.
  static const double xxl = 24;

  /// 32 dp.
  static const double xxxl = 32;
}

/// Corner radii.
abstract final class PaoRadius {
  /// Small elements such as badges.
  static const double sm = 8;

  /// Fields and icon tiles.
  static const double md = 12;

  /// Cards and banners.
  static const double lg = 16;

  /// Sheets.
  static const double xl = 24;

  /// Fully rounded pills.
  static const double pill = 999;
}

/// Minimum touch target (PRD §11, Material guidance).
const double minTapTarget = 48;
