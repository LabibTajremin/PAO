import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// How far ahead a session can be booked.
const bookingWindow = Duration(days: 90);

/// A date and a time button, both in Asia/Dhaka wall time.
class WhenFields extends StatelessWidget {
  /// Creates the fields.
  const WhenFields({
    required this.day,
    required this.time,
    required this.first,
    required this.onDay,
    required this.onTime,
    super.key,
  });

  /// Chosen day.
  final DateTime day;

  /// Chosen time.
  final TimeOfDay time;

  /// Earliest day allowed.
  final DateTime first;

  /// Called with a new day.
  final ValueChanged<DateTime> onDay;

  /// Called with a new time.
  final ValueChanged<TimeOfDay> onTime;

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: first,
      lastDate: first.add(bookingWindow),
    );
    if (picked != null) onDay(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) onTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final date = DateFormat('EEE d MMM y', context.lang).format(day);
    final clock = MaterialLocalizations.of(context).formatTimeOfDay(time);
    return Wrap(
      spacing: PaoSpace.md,
      runSpacing: PaoSpace.sm,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text('${t.level2Date}: $date'),
          onPressed: () => _pickDay(context),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.schedule),
          label: Text('${t.level2Time}: $clock'),
          onPressed: () => _pickTime(context),
        ),
      ],
    );
  }
}
