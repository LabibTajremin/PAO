import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Locale-aware formatting of API values for job, earnings and profile screens.
extension ApiFormats on BuildContext {
  /// The language code the app shows, `en` or `bn`.
  String get lang => Localizations.localeOf(this).languageCode;

  /// [text] in the current language.
  String local(LocalizedText text) => lang == 'bn' ? text.bn : text.en;

  /// An instant as Asia/Dhaka wall time.
  String when(DateTime at, [String pattern = 'd MMM y, h:mm a']) =>
      formatDhaka(at, pattern: pattern, locale: lang);

  /// A calendar date from the API (`yyyy-MM-dd`); it has no time, so no zone
  /// shift applies.
  String day(String date, [String pattern = 'd MMM y']) =>
      DateFormat(pattern, lang).format(DateTime.parse(date));

  /// A count in the current language's digits.
  String count(int value) => formatCount(value, locale: lang);
}
