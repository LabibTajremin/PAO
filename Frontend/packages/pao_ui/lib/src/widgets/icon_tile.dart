import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/shape.dart';
import 'package:pao_ui/src/widgets/service_icon.dart';

/// An icon on a tinted small leaf, as on the service grid.
class PaoIconTile extends StatelessWidget {
  /// Creates a tile with a Material icon.
  const PaoIconTile({required IconData this.icon, this.size = 48, super.key})
    : iconKey = null,
      iconUrl = null;

  /// Creates a tile with a category or service icon ([PaoServiceIcon]).
  const PaoIconTile.service({
    required String this.iconKey,
    this.iconUrl,
    this.size = 48,
    super.key,
  }) : icon = null;

  /// The Material icon, for tiles that are not a catalog item.
  final IconData? icon;

  /// The catalog icon key.
  final String? iconKey;

  /// The catalog item's uploaded icon.
  final String? iconUrl;

  /// Side length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    final glyph = icon;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.tintFill,
        borderRadius: PaoShape.leafSmall,
      ),
      child: glyph != null
          ? Icon(glyph, color: c.action, size: size / 2)
          : PaoServiceIcon(
              iconKey!,
              iconUrl: iconUrl,
              size: size / 2,
              color: c.action,
            ),
    );
  }
}
