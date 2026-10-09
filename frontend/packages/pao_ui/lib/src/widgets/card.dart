import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A white rounded surface; [highlighted] uses the accent tint.
class PaoCard extends StatelessWidget {
  /// Creates a card.
  const PaoCard({
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(PaoSpace.lg),
    super.key,
  });

  /// Content.
  final Widget child;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  /// Uses the accent tint instead of white.
  final bool highlighted;

  /// Inner spacing.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final radius = BorderRadius.circular(PaoRadius.lg);
    return Material(
      color: highlighted ? accent.tint : PaoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: highlighted ? accent.soft : PaoColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
