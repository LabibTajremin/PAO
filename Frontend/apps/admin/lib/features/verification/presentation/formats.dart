import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Locale-aware formatting of API values on the verification screens.
extension VerificationFormats on BuildContext {
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
}

/// The first eight characters of an ID, enough to tell records apart when
/// no name is known.
String shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
