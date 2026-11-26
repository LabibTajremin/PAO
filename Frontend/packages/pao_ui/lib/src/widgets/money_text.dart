import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/src/motion/count_up.dart';

/// An amount in paisa shown as taka in the current language, e.g. `৳1,130`.
/// Digits are tabular so amounts in a column line up, and a counting amount
/// keeps its width.
class PaoMoneyText extends StatelessWidget {
  /// Creates the text; [countUp] counts up to the amount, for dashboards only.
  const PaoMoneyText(this.paisa, {this.style, this.countUp = false, super.key});

  /// Whether the amount counts up from zero.
  final bool countUp;

  /// Amount in paisa (1 BDT = 100 paisa).
  final int paisa;

  /// Text style; defaults to the ambient style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => countUp
      ? PaoCountUp(value: paisa, builder: _text)
      : _text(context, paisa);

  Widget _text(BuildContext context, int amount) => Text(
    formatMoney(amount, locale: Localizations.localeOf(context).languageCode),
    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])
        .merge(style),
  );
}
