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
}
