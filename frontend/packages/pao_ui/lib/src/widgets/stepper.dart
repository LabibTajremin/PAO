import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A quantity picker with minus and plus buttons.
class PaoStepper extends StatelessWidget {
  /// Creates the stepper.
  const PaoStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    super.key,
  });

  /// Current quantity.
  final int value;

  /// Called with the new quantity.
  final ValueChanged<int> onChanged;

  /// Lowest allowed quantity.
  final int min;

  /// Highest allowed quantity.
  final int max;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    Widget button(IconData icon, String label, int? next) => IconButton(
      tooltip: label,
      onPressed: next == null ? null : () => onChanged(next),
      icon: Icon(icon),
      color: accent.primary,
      disabledColor: PaoColors.textTertiary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove, 'Less', value > min ? value - 1 : null),
        SizedBox(
          width: PaoSpace.xxxl,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        button(Icons.add, 'More', value < max ? value + 1 : null),
      ],
    );
  }
}
