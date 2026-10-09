import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// Tabs in a pill, e.g. Upcoming / Past.
class PaoSegmented<T> extends StatelessWidget {
  /// Creates the control; [segments] maps values to labels.
  const PaoSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Options in display order.
  final Map<T, String> segments;

  /// The current value.
  final T selected;

  /// Called with the tapped value.
  final ValueChanged<T> onChanged;

  Widget _segment(BuildContext context, T value, String label) {
    final accent = context.pao.accent;
    final on = value == selected;
    return Expanded(
      child: Semantics(
        selected: on,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(PaoRadius.pill),
          onTap: () => onChanged(value),
          child: Container(
            constraints: const BoxConstraints(minHeight: minTapTarget),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? accent.soft : null,
              borderRadius: BorderRadius.circular(PaoRadius.pill),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: on ? accent.strong : PaoColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(PaoSpace.xs),
    decoration: BoxDecoration(
      color: PaoColors.surface,
      borderRadius: BorderRadius.circular(PaoRadius.pill),
      border: Border.all(color: PaoColors.border),
    ),
    child: Row(
      children: [
        for (final MapEntry(key: value, value: label) in segments.entries)
          _segment(context, value, label),
      ],
    ),
  );
}
