import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/widgets/stitch.dart';

/// The vertical booking timeline: done steps are filled, the [current] one is
/// outlined in the accent, later ones are faint. Steps are joined by a kantha
/// stitch that is bright up to the current step.
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

  Widget _node(PaoColors c, int i) => SizedBox(
    width: 24,
    child: Column(
      children: [
        Icon(
          i < current
              ? Icons.check_circle
              : (i == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
          color: i <= current ? c.action : c.hairline,
        ),
        if (i < steps.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PaoSpace.xs),
            child: PaoStitch(
              axis: Axis.vertical,
              length: PaoSpace.xl,
              color: i < current ? c.stitch : c.hairline,
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (i, label) in steps.indexed)
          Semantics(
            label: label,
            selected: i == current,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _node(c, i),
                const SizedBox(width: PaoSpace.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: i <= current
                            ? text.titleSmall
                            : text.bodyMedium!.copyWith(color: c.inkFaint),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
