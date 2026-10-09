import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// An icon on a tinted rounded square, as on the service grid.
class PaoIconTile extends StatelessWidget {
  /// Creates a tile.
  const PaoIconTile({required this.icon, this.size = 48, super.key});

  /// The icon.
  final IconData icon;

  /// Side length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.tint,
        borderRadius: BorderRadius.circular(PaoRadius.md),
      ),
      child: Icon(icon, color: accent.primary, size: size / 2),
    );
  }
}
