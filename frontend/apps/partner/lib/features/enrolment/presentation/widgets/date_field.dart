import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A tappable field that opens the date picker.
class DateField extends StatelessWidget {
  /// Creates the field; dates run from [first] to [last].
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.first,
    required this.last,
    this.error,
    super.key,
  });

  /// Field label.
  final String label;

  /// The chosen date.
  final DateTime? value;

  /// Called with the picked date.
  final ValueChanged<DateTime> onChanged;

  /// Earliest date.
  final DateTime first;

  /// Latest date, also where the picker opens when nothing is chosen.
  final DateTime last;

  /// Validation message.
  final String? error;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? last,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? context.t.enrolPickDate
        : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(value!);
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          text,
          style: value == null
              ? const TextStyle(color: PaoColors.textTertiary)
              : null,
        ),
      ),
    );
  }
}
