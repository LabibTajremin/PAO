import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The two forms of the PAO mark (`design/brand/`).
enum PaoLogoVariant {
  /// The square app-icon tile.
  tile,

  /// The letters alone, about three times as wide as tall.
  wordmark,
}

/// The PAO logo from the brand SVGs. The ink version shows on light
/// backgrounds and the inverse (ivory) version on dark ones, following the
/// theme unless [inverse] says otherwise. Never recoloured with the accent
/// and never set in a font (ADR-0038).
class PaoLogo extends StatelessWidget {
  /// Creates the logo [height] logical pixels tall.
  const PaoLogo({
    this.variant = PaoLogoVariant.tile,
    this.height = 48,
    this.inverse,
    super.key,
  });

  /// Tile or wordmark.
  final PaoLogoVariant variant;

  /// Height; the width follows the artwork.
  final double height;

  /// Forces the inverse (true) or ink (false) version, for a logo on an
  /// image or a coloured band whose brightness the theme doesn't know.
  final bool? inverse;

  /// The asset for [variant] and [inverse], inside `pao_ui`.
  static String assetFor(PaoLogoVariant variant, {required bool inverse}) =>
      switch ((variant, inverse)) {
        (PaoLogoVariant.tile, false) => 'assets/brand/logo-tile-light.svg',
        (PaoLogoVariant.tile, true) => 'assets/brand/logo-tile-dark.svg',
        (PaoLogoVariant.wordmark, false) => 'assets/brand/wordmark-ink.svg',
        (PaoLogoVariant.wordmark, true) => 'assets/brand/wordmark-ivory.svg',
      };

  @override
  Widget build(BuildContext context) {
    final dark = inverse ?? Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      assetFor(variant, inverse: dark),
      package: 'pao_ui',
      height: height,
      semanticsLabel: 'PAO',
    );
  }
}
