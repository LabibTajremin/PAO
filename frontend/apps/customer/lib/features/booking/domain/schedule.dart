import 'dart:math';

/// Bangladesh has no daylight saving, so Dhaka wall time is always UTC+6.
const Duration _dhaka = Duration(hours: 6);

/// How far ahead a scheduled booking must start: the provider has up to 30
/// minutes to answer (D12) and then needs time to travel.
const Duration scheduleLead = Duration(hours: 1);

/// How far ahead a booking may be scheduled.
const Duration scheduleHorizon = Duration(days: 30);

/// The instant of a Dhaka wall-clock time, whatever the device's zone.
DateTime fromDhaka(DateTime day, int hour, int minute) =>
    DateTime.utc(day.year, day.month, day.day, hour, minute).subtract(_dhaka);

/// The Dhaka wall-clock date and time of [instant], as a zone-less value.
DateTime toDhaka(DateTime instant) {
  final t = instant.toUtc().add(_dhaka);
  return DateTime(t.year, t.month, t.day, t.hour, t.minute);
}

/// Whether [at] is far enough ahead of [now] to be scheduled.
bool schedulable(DateTime at, DateTime now) =>
    !at.isBefore(now.add(scheduleLead)) &&
    !at.isAfter(now.add(scheduleHorizon));

/// A fresh idempotency key for one booking confirmation (PRD §9.6).
String newIdempotencyKey([Random? random]) {
  final r = random ?? Random.secure();
  return [
    for (var i = 0; i < 16; i++)
      r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
