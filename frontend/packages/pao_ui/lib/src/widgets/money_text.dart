import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// An amount in paisa shown as taka in the current language, e.g. `৳1,130`.
class PaoMoneyText extends StatelessWidget {
  /// Creates the text.
  const PaoMoneyText(this.paisa, {this.style, super.key});

  /// Amount in paisa (1 BDT = 100 paisa).
  final int paisa;

  /// Text style; defaults to the ambient style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    formatMoney(paisa, locale: Localizations.localeOf(context).languageCode),
    style: style,
  );
}
