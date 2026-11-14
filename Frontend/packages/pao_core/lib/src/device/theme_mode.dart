import 'package:flutter/material.dart';
import 'package:pao_core/src/device/prefs.dart';

/// The chosen light, dark or system appearance, saved on the device.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  /// Starts at the mode saved in `prefs`, following the system when none is.
  ThemeModeController(this._prefs) : super(_read(_prefs));

  final Prefs _prefs;

  /// Key of the chosen appearance.
  static const key = 'pao.theme';

  /// Switches to [mode] and saves it.
  Future<void> select(ThemeMode mode) async {
    value = mode;
    await _prefs.setString(key, mode.name);
  }

  static ThemeMode _read(Prefs prefs) => ThemeMode.values.firstWhere(
    (m) => m.name == prefs.string(key),
    orElse: () => ThemeMode.system,
  );
}
