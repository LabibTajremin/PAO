import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the appearance is light until one is chosen and saved', () async {
    SharedPreferences.setMockInitialValues({ThemeModeController.key: 'bogus'});
    final prefs = await Prefs.open();
    final modes = ThemeModeController(prefs);
    expect(modes.value, ThemeMode.light);
    await modes.select(ThemeMode.dark);
    expect(modes.value, ThemeMode.dark);
    expect(ThemeModeController(prefs).value, ThemeMode.dark);
    modes.value = ThemeMode.system;
    await Future<void>.delayed(Duration.zero);
    expect(ThemeModeController(prefs).value, ThemeMode.system);
  });
}
