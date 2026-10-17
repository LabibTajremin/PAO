import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// A leaf-shaped surface with a hairline edge; [highlighted] uses the accent
/// tint.
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
    return Material(
      color: highlighted ? c.tintFill : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: PaoShape.leaf,
        side: BorderSide(color: highlighted ? c.selectedFill : c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
