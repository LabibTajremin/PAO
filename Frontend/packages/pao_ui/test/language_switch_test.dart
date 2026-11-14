import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets('switches the language', (tester) async {
    final c = LocaleController();
    await pumpPao(tester, PaoLanguageSwitch(controller: c));
    await tester.tap(find.text('English'));
    await tester.pump();
    expect(c.value, PaoLocales.english);
  });

  testWidgets('switches the appearance', (tester) async {
    final mode = ValueNotifier(ThemeMode.system);
    await pumpPao(
      tester,
      PaoThemeModeSwitch(
        mode: mode,
        labels: const {
          ThemeMode.system: 'System',
          ThemeMode.light: 'Light',
          ThemeMode.dark: 'Dark',
        },
        onChanged: (m) => mode.value = m,
      ),
    );
    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(mode.value, ThemeMode.dark);
  });
}
