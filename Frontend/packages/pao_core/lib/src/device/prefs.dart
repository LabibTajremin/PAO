import 'package:shared_preferences/shared_preferences.dart';

/// Small non-secret settings that survive restarts, such as the chosen
/// language.
class Prefs {
  Prefs._(this._prefs);

  final SharedPreferences _prefs;

  /// Opens the store.
  static Future<Prefs> open() async =>
      Prefs._(await SharedPreferences.getInstance());

  /// Key of the chosen language code.
  static const languageKey = 'pao.language';

  /// Key set once onboarding is done.
  static const onboardedKey = 'pao.onboarded';

  /// Reads a string.
  String? string(String key) => _prefs.getString(key);

  /// Writes a string.
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  /// Reads a flag, false when unset.
  bool flag(String key) => _prefs.getBool(key) ?? false;

  /// Writes a flag.
  Future<void> setFlag(String key, {required bool value}) =>
      _prefs.setBool(key, value);
}
