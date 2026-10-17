import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Locale-aware formatting of API values on the people, bookings and
/// complaints screens.
extension OpsFormats on BuildContext {
  /// The language code the panel shows, `en` or `bn`.
  String get lang => Localizations.localeOf(this).languageCode;

  /// [text] in the current language.
  String local(LocalizedText text) => lang == 'bn' ? text.bn : text.en;

  /// An instant as Asia/Dhaka wall time.
  String when(DateTime at, [String pattern = 'd MMM y, h:mm a']) =>
      formatDhaka(at, pattern: pattern, locale: lang);

  /// A calendar date from the API (`yyyy-MM-dd`); it has no time, so no zone
  /// shift applies.
  String day(String date) =>
      DateFormat('d MMM y', lang).format(DateTime.parse(date));

  /// A count in the current language's digits.
  String count(int value) => formatCount(value, locale: lang);

  /// An amount in paisa as taka.
  String money(int paisa) => formatMoney(paisa, locale: lang);

  /// A star rating with one decimal, e.g. `4.8`.
  String rating(double value) =>
      NumberFormat('0.0', lang == 'bn' ? 'bn' : 'en').format(value);
}

/// A calendar date as the API takes it, `yyyy-MM-dd`.
String apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
