import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pao_l10n/pao_l10n.dart';

void main() {
  test('money uses South Asian grouping and Bangla digits', () {
    expect(formatMoney(113000), '৳1,130');
    expect(formatMoney(10000000), '৳1,00,000');
    expect(formatMoney(12345), '৳123.45');
    expect(formatMoney(113000, locale: 'bn'), '৳১,১৩০');
  });

  test('counts', () {
    expect(formatCount(12), '12');
    expect(formatCount(12, locale: 'bn'), '১২');
  });

  test('times are shown in Asia/Dhaka', () async {
    await initializeDateFormatting('bn');
    final t = DateTime.utc(2026, 10, 9, 18, 30);
    expect(formatDhaka(t), '10 Oct 2026, 12:30 AM');
    expect(formatDhaka(t, pattern: 'HH:mm'), '00:30');
    expect(formatDhaka(t, pattern: 'd', locale: 'bn'), '১০');
  });

  // Every code in the switch, so no API code ships untranslated.
  final codes = RegExp("'([A-Z0-9_]+)':")
      .allMatches(File('lib/src/failure_messages.dart').readAsStringSync())
      .map((m) => m.group(1)!)
      .toList();

  testWidgets('every failure code has a message in both languages', (
    tester,
  ) async {
    for (final locale in PaoLocales.all) {
      final l10n = await PaoL10n.delegate.load(locale);
      for (final code in codes) {
        expect(failureMessage(l10n, code), isNotEmpty);
      }
    }
    expect(codes, hasLength(61));
    final en = await PaoL10n.delegate.load(const Locale('en'));
    expect(failureMessage(en, 'WHO_KNOWS'), en.failureUnexpected);
    expect(en.itemCount(2), '2 items');
    expect(en.ratingLabel('4.5'), '4.5 out of 5 stars');
  });
}
