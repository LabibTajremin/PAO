// The screen tour (P28): every main screen in light/dark × en/bn, failing on
// any layout error. With --update-goldens it also writes docs/screenshots/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

/// Real Bangla for the fixtures' placeholder names.
const _bangla = {
  'Electrician': 'ইলেকট্রিশিয়ান',
  'Fan repair': 'ফ্যান মেরামত',
  'Switch repair': 'সুইচ মেরামত',
  'Ceiling or table fan': 'সিলিং বা টেবিল ফ্যান',
  'Cleaning': 'পরিষ্কার',
  'Spare parts': 'যন্ত্রাংশ',
  'Home salon': 'হোম সেলুন',
  'Haircut': 'চুল কাটা',
  'Driver': 'ড্রাইভার',
  'Hourly': 'ঘণ্টা হিসেবে',
  'Daily': 'দিন হিসেবে',
  'Beauty': 'সৌন্দর্য',
  'Repairs': 'মেরামত',
};

/// [json] with every `{en, bn}` name given its real Bangla.
Object? withBangla(Object? json) => switch (json) {
  {'en': final String en, 'bn': _} when json.length == 2 => {
    'en': en,
    'bn': _bangla[en] ?? en,
  },
  final Map<String, Object?> map => {
    for (final e in map.entries) e.key: withBangla(e.value),
  },
  final List<Object?> list => [for (final v in list) withBangla(v)],
  _ => json,
};

/// Loads Inter, Noto Sans Bengali and the Material icons, so screenshots show
/// real text and icons.
Future<void> loadTourFonts() async {
  // Release builds show no debug ribbon, so the screenshots don't either.
  WidgetsApp.debugAllowBannerOverride = false;
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/root/flutter';
  for (final (family, file) in [
    (PaoFonts.latin, '../../packages/pao_ui/fonts/Inter-Variable.ttf'),
    (
      PaoFonts.bangla,
      '../../packages/pao_ui/fonts/NotoSansBengali-Variable.ttf',
    ),
    (
      'MaterialIcons',
      '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  ]) {
    final bytes = File(file).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

/// The four looks every screen is checked in.
const List<(ThemeMode, String)> tourVariants = [
  (ThemeMode.light, 'en'),
  (ThemeMode.dark, 'en'),
  (ThemeMode.light, 'bn'),
  (ThemeMode.dark, 'bn'),
];

/// A phone screen: 393 × 852 at 1×.
void phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(393, 852)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Saves the screen as `docs/screenshots/<app>/<name>.png` when goldens are
/// being updated; a normal run only checks the layout.
Future<void> capture(WidgetTester tester, String app, String name) async {
  expect(tester.takeException(), isNull);
  if (!autoUpdateGoldenFiles) return;
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('../../../../../docs/screenshots/$app/$name.png'),
  );
}
