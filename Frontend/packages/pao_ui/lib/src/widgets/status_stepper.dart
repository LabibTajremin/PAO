import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/motion.dart';
import 'package:pao_ui/src/widgets/stitch.dart';

/// The vertical booking timeline: done steps are filled, the [current] one is
/// outlined in the accent, later ones are faint. Steps are joined by a kantha
/// stitch that is bright up to the current step; the stitch into the current
/// step fills from the top (`emphasis`) whenever [current] moves on.
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
            child: i == current - 1
                ? _Filling(key: ValueKey(current), c: c)
                : _stitch(i < current ? c.stitch : c.hairline),
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

Widget _stitch(Color color) =>
    PaoStitch(axis: Axis.vertical, length: PaoSpace.xl, color: color);

/// The stitch into the current step, drawn bright over the faint one by a
/// vertical scale from the top, so only a transform animates.
class _Filling extends StatelessWidget {
  const _Filling({required this.c, super.key});

  final PaoColors c;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: context.lightMotion ? 1 : 0, end: 1),
    duration: PaoMotion.emphasis,
    curve: PaoMotion.emphasized,
    child: _stitch(c.stitch),
    // The faint stitch shows only while the bright one is still filling; the
    // bright one is see-through, so both at once would read darker.
    builder: (_, fill, line) => Stack(
      children: [
        if (fill < 1) _stitch(c.hairline),
        Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.diagonal3Values(1, fill, 1),
          child: line,
        ),
      ],
    ),
  );
}
