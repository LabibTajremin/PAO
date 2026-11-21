import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pao_core/src/device/prefs.dart';

/// The chosen light, dark or system appearance, saved on the device.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  /// Starts at the mode saved in `prefs`, light when none is (ADR-0038): PAO
  /// opens light, and dark mode is a choice in Appearance.
  ThemeModeController(this._prefs) : super(_read(_prefs));

  final Prefs _prefs;

  /// Key of the chosen appearance.
  static const key = 'pao.theme';

  /// Switches to [mode] and saves it.
  Future<void> select(ThemeMode mode) async {
    super.value = mode;
    await _prefs.setString(key, mode.name);
  }

  // Setting the value directly saves it too, so code that only knows a
  // ValueNotifier<ThemeMode> still remembers the choice.
  @override
  set value(ThemeMode mode) => unawaited(select(mode));

  static ThemeMode _read(Prefs prefs) => ThemeMode.values.firstWhere(
    (m) => m.name == prefs.string(key),
    orElse: () => ThemeMode.light,
  );
}
