import 'package:flutter/widgets.dart';

/// The languages PAO ships in (PRD §11): English and Bangla.
abstract final class PaoLocales {
  /// English, the fallback language.
  static const Locale english = Locale('en');

  /// Bangla.
  static const Locale bangla = Locale('bn');

  /// Every supported locale, fallback first.
  static const List<Locale> all = [english, bangla];
}
