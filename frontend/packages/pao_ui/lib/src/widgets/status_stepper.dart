import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// The vertical booking timeline: done steps are filled, the [current] one is
/// outlined in the accent, later ones are grey.
class PaoStatusStepper extends StatelessWidget {
  /// Creates the timeline.
  const PaoStatusStepper({
    required this.steps,
    required this.current,
    super.key,
  });

  /// Step labels in order.
  final List<String> steps;

  /// Index of the current step.
  final int current;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (i, label) in steps.indexed)
          Semantics(
            label: label,
            selected: i == current,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PaoSpace.sm),
              child: Row(
                children: [
                  Icon(
                    i < current
                        ? Icons.check_circle
                        : (i == current
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked),
                    color: i <= current ? accent.primary : PaoColors.border,
                  ),
                  const SizedBox(width: PaoSpace.md),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: i <= current
                            ? text.titleSmall
                            : text.bodyMedium!.copyWith(
                                color: PaoColors.textTertiary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
