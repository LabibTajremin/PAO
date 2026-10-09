import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A selectable pill, e.g. a filter or review tag.
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
    final accent = context.pao.accent;
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PaoRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: PaoSpace.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent.soft : PaoColors.surface,
            borderRadius: BorderRadius.circular(PaoRadius.pill),
            border: Border.all(
              color: selected ? accent.primary : PaoColors.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: selected ? accent.strong : PaoColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
