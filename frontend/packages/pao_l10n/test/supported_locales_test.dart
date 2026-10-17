import 'package:flutter_test/flutter_test.dart';
import 'package:pao_l10n/pao_l10n.dart';

void main() {
  test('supports English first, then Bangla', () {
    expect(PaoLocales.all.map((l) => l.languageCode), ['en', 'bn']);
  });
}
