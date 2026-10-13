import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// A selectable pill, e.g. a filter or review tag; once selected it takes the
/// leaf shape so the choice reads at a glance.
class PaoChip extends StatelessWidget {
  /// Creates a chip.
  const PaoChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Chip text.
  final String label;

  /// Whether the chip is on.
  final bool selected;

  /// Toggles the chip; null makes it read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    final shape = selected
        ? PaoShape.leaf
        : BorderRadius.circular(PaoRadius.pill);
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: AnimatedContainer(
          duration: PaoMotion.fast,
          curve: PaoMotion.curve,
          constraints: const BoxConstraints(minHeight: minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: PaoSpace.lg + 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.selectedFill : c.card,
            borderRadius: shape,
            border: Border.all(color: selected ? c.action : c.hairline),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!
                .copyWith(color: selected ? c.selectedInk : c.inkMuted),
          ),
        ),
      ),
    );
  }
}
