import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _queue = '/v1/admin/verifications';

Future<Harness> _open(
  WidgetTester tester,
  Object? body, {
  int code = 200,
}) async {
  final h = Harness.create();
  await h.signIn(tester);
  h.http.onGet(_queue, (s) => s.reply(code, body));
  await h.pumpApp(tester, Routes.verification);
  return h;
}

void main() {
  testWidgets('the queue lists waiting providers, oldest first', (
    tester,
  ) async {
    desktop(tester);
    final h = await _open(
      tester,
      queue([
        queueRow(id: karim, name: 'Karim Mia', age: 50),
        queueRow(age: 30, pending: ['police_clearance']),
        queueRow(id: 'p3', name: 'Nasima Akter', age: 1),
      ]),
    );
    expect(find.text('Verification queue'), findsOneWidget);
    expect(find.text('Karim Mia'), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
    expect(find.text('30 hours'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
    expect(find.text('Electrician'), findsNWidgets(3));
    expect(find.widgetWithText(PaoBadge, 'National ID'), findsNWidgets(2));
    expect(find.widgetWithText(PaoBadge, 'Police clearance'), findsOne);
    expect(h.sent.last.queryParameters['itemType'], isNull);
    h.http.onGet('$_queue/$rahim', (s) => s.reply(200, reviewJson()));
    await tester.tap(find.text('Rahim Uddin'));
    await h.settle(tester);
    expect(find.text('NID and profile'), findsOneWidget);
  });

  testWidgets('the item filter asks the API for that item only', (
    tester,
  ) async {
    narrow(tester);
    final h = await _open(tester, queue([queueRow()]));
    await tester.tap(find.byType(DropdownMenu<ItemType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Live selfie').last);
    await h.settle(tester);
    expect(h.sent.last.queryParameters['itemType'], 'selfie');
    await tester.tap(find.byType(DropdownMenu<ItemType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'All items').last);
    await h.settle(tester);
    expect(h.sent.last.queryParameters['itemType'], isNull);
  });

  testWidgets('an empty queue says nobody is waiting', (tester) async {
    desktop(tester);
    await _open(tester, queue([]));
    expect(find.text('No providers are waiting for review.'), findsOneWidget);
  });

  testWidgets('a failed queue can be retried', (tester) async {
    desktop(tester);
    final h = await _open(tester, apiError('INTERNAL'), code: 500);
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
    h.http.onGet(_queue, (s) => s.reply(200, queue([queueRow()])));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.byType(InkWell), findsWidgets);
    expect(find.text('Rahim Uddin'), findsOneWidget);
  });

  testWidgets('the queue and review read in Bangla', (tester) async {
    desktop(tester);
    final h = Harness.create();
    h.services.locale.select(PaoLocales.bangla);
    await h.signIn(tester);
    h.http.onGet(_queue, (s) => s.reply(200, queue([queueRow(age: 72)])));
    await h.pumpApp(tester, Routes.verification);
    expect(find.text('যাচাইয়ের সারি'), findsOneWidget);
    expect(find.text('ইলেকট্রিশিয়ান'), findsOneWidget);
    expect(find.text('৩ দিন'), findsOneWidget);
    h.http.onGet('$_queue/$rahim', (s) => s.reply(200, reviewJson()));
    await h.go(tester, Routes.reviewOf(rahim));
    expect(find.text('এনআইডি ও প্রোফাইল'), findsOneWidget);
    expect(find.text('১৭ মে ১৯৯০'), findsOneWidget);
  });
}
