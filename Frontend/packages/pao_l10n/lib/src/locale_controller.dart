import 'package:flutter/widgets.dart';
import 'package:pao_l10n/src/supported_locales.dart';

/// The language the app shows; Bangla unless the user picks English (C-15).
class LocaleController extends ValueNotifier<Locale> {
  /// Creates the controller starting at [initial].
  // ValueNotifier names its parameter `_value`, which no subclass can match.
  // ignore: matching_super_parameters
  LocaleController([super.initial = PaoLocales.bangla]);

  /// Whether Bangla is active.
  bool get isBangla => value.languageCode == PaoLocales.bangla.languageCode;

  /// Switches to [locale] if it is supported.
  void select(Locale locale) {
    if (PaoLocales.all.contains(locale)) value = locale;
  }
}
