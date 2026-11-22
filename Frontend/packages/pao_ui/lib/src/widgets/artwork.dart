import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The admin-replaceable illustration slots and their size in pixels
/// (06-update §5, ADR-0040). Each app bundles the seed of each slot.
const paoArtworkSlots = <String, Size>{
  'customer.signin.hero': Size(1170, 1200),
  'customer.onboarding.1': Size(1170, 1080),
  'customer.onboarding.2': Size(1170, 1080),
  'customer.onboarding.3': Size(1170, 1080),
  'partner.signin.hero': Size(1170, 1200),
  'partner.onboarding.1': Size(1170, 1080),
  'partner.onboarding.2': Size(1170, 1080),
  'partner.onboarding.3': Size(1170, 1080),
  'empty.bookings': Size(720, 540),
  'empty.search': Size(720, 540),
  'empty.notifications': Size(720, 540),
  'empty.jobs': Size(720, 540),
  'offline': Size(720, 540),
  'success.booking': Size(720, 720),
  'success.job': Size(720, 720),
  'admin.login.hero': Size(1600, 1200),
};

/// An illustration slot: the seed the app bundles until the server's image is
/// cached, then that image. The box keeps the slot's ratio, so the swap never
/// moves the layout.
class PaoArtwork extends StatelessWidget {
  /// Creates the slot [slot]; [image] is the cached server file, if any.
  const PaoArtwork(this.slot, {this.image, this.isSvg = true, super.key});

  /// The slot key, one of [paoArtworkSlots].
  final String slot;

  /// The server's image, once downloaded; null shows the bundled seed.
  final Uint8List? image;

  /// Whether [image] is SVG rather than PNG or WebP.
  final bool isSvg;

  /// The bundled seed of [slot].
  static String assetFor(String slot) => 'assets/artwork/$slot.svg';

  @override
  Widget build(BuildContext context) {
    final size = paoArtworkSlots[slot]!;
    final seed = SvgPicture.asset(assetFor(slot), package: 'pao_ui');
    final file = image;
    final Widget picture;
    if (file == null) {
      picture = seed;
    } else if (isSvg) {
      picture = SvgPicture.memory(file, errorBuilder: (_, _, _) => seed);
    } else {
      picture = Image.memory(file, errorBuilder: (_, _, _) => seed);
    }
    // Illustrations carry no meaning the text around them does not say.
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: size.width / size.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(file), child: picture),
        ),
      ),
    );
  }
}

/// An SVG, PNG or WebP image loaded from [url], for admin previews; [fallback]
/// shows while it loads and if it fails.
class PaoRemoteImage extends StatelessWidget {
  /// Creates the image.
  const PaoRemoteImage(this.url, {required this.fallback, super.key});

  /// Where the image is.
  final String url;

  /// What to show instead.
  final Widget fallback;

  @override
  Widget build(BuildContext context) =>
      Uri.parse(url).path.toLowerCase().endsWith('.svg')
      ? SvgPicture.network(
          url,
          placeholderBuilder: (_) => fallback,
          errorBuilder: (_, _, _) => fallback,
        )
      : Image.network(url, errorBuilder: (_, _, _) => fallback);
}
