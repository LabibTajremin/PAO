import 'package:flutter/material.dart';
import 'package:pao_customer/features/booking/domain/schedule.dart';

/// Asks for a date then a time, both as Dhaka wall time, and returns the
/// instant; null when either picker is dismissed.
Future<DateTime?> pickSchedule(
  BuildContext context,
  DateTime now,
  DateTime? current,
) async {
  final start = current != null && schedulable(current, now)
      ? current
      : now.add(scheduleLead);
  final wall = toDhaka(start);
  final today = toDhaka(now);
  final day = await showDatePicker(
    context: context,
    initialDate: wall,
    firstDate: DateTime(today.year, today.month, today.day),
    lastDate: toDhaka(now.add(scheduleHorizon)),
  );
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: wall.hour, minute: wall.minute),
  );
  return time == null ? null : fromDhaka(day, time.hour, time.minute);
}
