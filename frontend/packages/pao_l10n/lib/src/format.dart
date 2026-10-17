import 'package:intl/intl.dart';

/// Bangladesh is UTC+6 all year (no daylight saving), so a fixed offset is
/// exact.
const dhakaOffset = Duration(hours: 6);

/// Formats amounts in paisa as taka with South Asian grouping, e.g. `৳1,130` or
/// `৳১,১৩০` in Bangla. Whole amounts drop the decimals.
String formatMoney(int paisa, {String locale = 'en'}) {
  final digits = paisa % 100 == 0 ? 0 : 2;
  final format = NumberFormat.decimalPatternDigits(
    locale: _numberLocale(locale),
    decimalDigits: digits,
  );
  return '৳${format.format(paisa / 100)}';
}

/// Formats a count with the locale's digits, e.g. `১২` in Bangla.
String formatCount(int count, {String locale = 'en'}) =>
    NumberFormat.decimalPattern(_numberLocale(locale)).format(count);

/// Formats an instant as Asia/Dhaka wall time with an intl [pattern], e.g.
/// `d MMM, h:mm a`. Call `initializeDateFormatting` once before using Bangla.
String formatDhaka(
  DateTime instant, {
  String pattern = 'd MMM y, h:mm a',
  String locale = 'en',
}) {
  final local = instant.toUtc().add(dhakaOffset);
  final wall = DateTime(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
  );
  return DateFormat(pattern, locale).format(wall);
}

String _numberLocale(String locale) => locale == 'bn' ? 'bn' : 'en_IN';
