import 'dart:typed_data';

/// A server illustration, downloaded and cached (ADR-0040).
class LookImage {
  /// Creates the image.
  const LookImage(this.bytes, {required this.isSvg, required this.version});

  /// The file.
  final Uint8List bytes;

  /// Whether it is SVG rather than PNG or WebP.
  final bool isSvg;

  /// The slot's version it came from.
  final int version;
}

/// What an app shows without a release: the tagline and the illustrations the
/// admin replaced. Slots missing here show the bundled seed.
class AppLook {
  /// Creates the look.
  const AppLook({
    this.taglineEn = seedTaglineEn,
    this.taglineBn = seedTaglineBn,
    this.artwork = const {},
  });

  /// The English seed tagline (06-update §6).
  static const seedTaglineEn = 'Ask for it. PAO it.';

  /// The Bangla seed tagline.
  static const seedTaglineBn = 'যা চাও, তাই PAO';

  /// The tagline in English.
  final String taglineEn;

  /// The tagline in Bangla.
  final String taglineBn;

  /// Cached server illustrations by slot key.
  final Map<String, LookImage> artwork;

  /// The tagline in [languageCode] (`bn` or anything else for English).
  String tagline(String languageCode) =>
      languageCode == 'bn' ? taglineBn : taglineEn;
}
