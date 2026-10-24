import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';

import '../../support/harness.dart';

Future<Harness> _start(WidgetTester tester) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  return h;
}

void main() {
  testWidgets('language is kept on the phone and the profile (C26)', (
    tester,
  ) async {
    final h = await _start(tester);
    h.http.onPut(
      '/v1/customer/profile',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await h.pumpApp(tester, Routes.accountPage('language'));
    await tester.tap(find.text('বাংলা'));
    await h.settle(tester);
    expect(h.services.prefs.string(Prefs.languageKey), 'bn');
    expect(h.bodyOf('/v1/customer/profile'), {
      'name': 'Nusrat Jahan',
      'language': 'bn',
    });
    expect(find.textContaining('এই ফোনে সংরক্ষিত'), findsOneWidget);
    h.http.onPut('/v1/customer/profile', (s) => s.reply(200, profile()));
    await tester.tap(find.text('English'));
    await h.settle(tester);
    expect(h.services.prefs.string(Prefs.languageKey), 'en');
    expect(find.textContaining('Saved on this phone'), findsNothing);
    h.services.gate.clear();
    await tester.tap(find.text('বাংলা'));
    await h.settle(tester);
    expect(h.services.prefs.string(Prefs.languageKey), 'bn');
    final puts = h.sent.where(
      (o) => o.method == 'PUT' && o.path == '/v1/customer/profile',
    );
    expect(puts, hasLength(2));
    await h.go(tester, Routes.account);
    h.services.locale.select(const Locale('en'));
    await h.settle(tester);
    expect(h.services.prefs.string(Prefs.languageKey), 'bn');
  });

  testWidgets('help expands topics, calls and emails support (C27)', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.pumpApp(tester, Routes.accountPage('help'));
    await tester.tap(find.text('What is the start code?'));
    await h.settle(tester);
    expect(find.textContaining('4-digit code'), findsOneWidget);
    await tester.tap(find.text('Call support'));
    await tester.tap(find.text('Email support'));
    await h.settle(tester);
    expect(h.launched.map((u) => u.toString()), [
      'tel:09610000000',
      'mailto:support@pao.com.bd?subject=PAO%20support%20request',
    ]);
  });

  testWidgets('terms and privacy read without signing in (C28)', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    await h.pumpApp(tester, Routes.legal);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Your choices'), findsOneWidget);
  });
}
