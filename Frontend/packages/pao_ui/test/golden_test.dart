import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

/// The bundled families, so the images show real Inter and Bangla text
/// instead of the test font's boxes.
Future<void> loadFonts() async {
  for (final (family, file) in [
    (PaoFonts.latin, 'fonts/Inter-Variable.ttf'),
    (PaoFonts.bangla, 'fonts/NotoSansBengali-Variable.ttf'),
  ]) {
    final bytes = File(file).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

void main() {
  setUpAll(loadFonts);

  for (final dark in [false, true]) {
    for (final lang in ['en', 'bn']) {
      final name = '${dark ? 'dark' : 'light'}_$lang';
      testWidgets('every component, $name', (tester) async {
        tester.view
          ..physicalSize = const Size(400, 3000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpPao(tester, PaoGalleryPage(dark: dark), locale: Locale(lang));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(PaoGalleryPage),
          matchesGoldenFile('goldens/gallery_$name.png'),
        );
      });
    }
  }
}
