import 'package:flutter/material.dart';
import 'package:pao_ui/src/motion/pressable.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// A white card lifted by a soft navy shadow in light mode, and an edged navy
/// surface in dark mode, where shadows don't show; [highlighted] uses the
/// accent tint.
class PaoCard extends StatelessWidget {
  /// Creates a card.
  const PaoCard({
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(PaoSpace.xl),
    super.key,
  });

  /// Content.
  final Widget child;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  /// Uses the accent tint instead of the card colour.
  final bool highlighted;

  /// Inner spacing.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    final lifted = !c.dark && !highlighted;
    final edge = highlighted ? c.selectedFill : c.hairline;
    return PaoPressable(
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: PaoShape.leaf,
          boxShadow: lifted ? PaoColors.cardShadow : null,
        ),
        child: Material(
          color: highlighted ? c.tintFill : c.card,
          shape: RoundedRectangleBorder(
            borderRadius: PaoShape.leaf,
            side: lifted ? BorderSide.none : BorderSide(color: edge),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
