import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// An icon on a tinted small leaf, as on the service grid.
class PaoIconTile extends StatelessWidget {
  /// Creates a tile.
  const PaoIconTile({required this.icon, this.size = 48, super.key});

  /// The icon.
  final IconData icon;

  /// Side length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.tintFill,
        borderRadius: PaoShape.leafSmall,
      ),
      child: Icon(icon, color: c.action, size: size / 2),
    );
  }
}
