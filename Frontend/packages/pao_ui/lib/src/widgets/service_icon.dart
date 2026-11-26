import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pao_ui/src/tokens/colors.dart';

/// The library icons every app ships (`assets/icons/<key>.svg`), in the admin
/// picker's order. The backend lists the same keys (`IconLibrary.Keys`).
const paoIconKeys = [
  'plumbing',
  'electrician',
  'ac',
  'appliance',
  'cleaning',
  'deep-clean',
  'pest-control',
  'painting',
  'carpentry',
  'gas-stove',
  'water-filter',
  'salon',
  'spa',
  'grooming',
  'driver',
  'car-wash',
  'moving',
  'laundry',
  'tailoring',
  'babysitting',
  'elderly-care',
  'nursing',
  'tutoring',
  'homemade-food',
  'catering',
  'bazar',
  'grocery',
  'chef',
  'gardening',
  'cctv',
  'wifi',
  'mobile-repair',
  'computer-repair',
  'photography',
  'decoration',
  'security',
  'courier',
  'tools',
  'beauty',
  'food',
];

/// The icon used for a key the library does not have.
const paoFallbackIconKey = 'tools';

/// A category or service icon in one colour: the admin's uploaded icon when
/// there is one, else the library icon for [iconKey]. Uploaded icons are drawn
/// as a mask, so a coloured PNG shows as its silhouette in the accent colour.
class PaoServiceIcon extends StatelessWidget {
  /// Creates the icon.
  const PaoServiceIcon(
    this.iconKey, {
    this.iconUrl,
    this.size = 24,
    this.color,
    super.key,
  });

  /// The library key; unknown keys show the generic tools icon.
  final String iconKey;

  /// An uploaded or linked icon (ADR-0039); wins over [iconKey].
  final String? iconUrl;

  /// Side length.
  final double size;

  /// The colour; defaults to the surrounding icon colour, then the accent.
  final Color? color;

  /// The asset path of [key], falling back for unknown keys.
  static String assetFor(String key) =>
      'assets/icons/${paoIconKeys.contains(key) ? key : paoFallbackIconKey}.svg';

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? context.pao.action;
    final filter = ColorFilter.mode(tint, BlendMode.srcIn);
    final library = SvgPicture.asset(
      assetFor(iconKey),
      package: 'pao_ui',
      width: size,
      height: size,
      colorFilter: filter,
    );
    final url = iconUrl;
    final Widget icon;
    if (url == null) {
      icon = library;
    } else if (Uri.parse(url).path.toLowerCase().endsWith('.svg')) {
      icon = SvgPicture.network(
        url,
        width: size,
        height: size,
        colorFilter: filter,
        errorBuilder: (_, _, _) => library,
      );
    } else {
      icon = Image.network(
        url,
        width: size,
        height: size,
        color: tint,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, _, _) => library,
      );
    }
    // The name next to the icon is what screen readers announce.
    return ExcludeSemantics(child: icon);
  }
}
