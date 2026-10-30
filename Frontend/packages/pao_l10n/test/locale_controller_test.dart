import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_l10n/pao_l10n.dart';

void main() {
  test('starts in Bangla and switches only to supported locales', () {
    final c = LocaleController();
    expect(c.isBangla, isTrue);
    c.select(const Locale('fr'));
    expect(c.value, PaoLocales.bangla);
    c.select(PaoLocales.english);
    expect([c.value, c.isBangla], [PaoLocales.english, false]);
  });
}
