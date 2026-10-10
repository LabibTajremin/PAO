import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_detail_page.dart';
import 'package:pao_admin/features/customers/presentation/customer_detail_page.dart';
import 'package:pao_admin/features/customers/presentation/customers_page.dart';

import '../../support/harness.dart';
import '../providers/fixtures.dart';
import 'fixtures.dart';

const _list = '/v1/admin/customers';
const _detail = '/v1/admin/customers/$customerId';
const _status = '/v1/admin/customers/$customerId/status';
final String _path = Routes.detail(Routes.customers, customerId);

void main() {
  testWidgets('customers can be searched, filtered and opened', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(
      _list,
      (s) => s.reply(200, {
        'items': [
          customerSummary(),
          customerSummary(id: 'c2', rating: null, phone: null),
        ],
      }),
    );
    await h.pumpApp(tester, Routes.customers);
    expect(find.text('Nusrat Jahan'), findsNWidgets(2));
    expect(find.text('+8801812345678'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    expect(find.text('10 Feb 2026'), findsNWidgets(2));
    await choose(tester, h, 'Status: Any', 'Banned');
    final sent = h.sent.lastWhere((o) => o.path == _list).queryParameters;
    expect(sent['status'], 'banned');
    await tester.enterText(find.byType(TextField), 'Nusrat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    final searched = h.sent.lastWhere((o) => o.path == _list).queryParameters;
    expect(searched, containsPair('q', 'Nusrat'));
    expect(searched, containsPair('status', 'banned'));
    await tester.tap(find.text('Nusrat Jahan').first);
    await h.settle(tester);
    expect(find.byType(CustomerDetailPage), findsOneWidget);
  });

  testWidgets('an empty or failed customer list says so', (tester) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_list, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.pumpApp(tester, Routes.customers);
    expect(find.text('No customers match these filters.'), findsOneWidget);
    h.http.onGet(_list, (s) => s.reply(500, apiError('INTERNAL')));
    await choose(tester, h, 'Status: Any', 'Active');
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a customer shows bookings, complaints and history', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(_detail, (s) => s.reply(200, customerDetail()))
      ..onPost(_status, (s) => s.reply(200, customerDetail(status: 'banned')));
    await h.pumpApp(tester, _path);
    for (final text in [
      'Nusrat Jahan',
      '+8801812345678',
      '14',
      '4.5',
      'PAO-104233 · Fan repair',
      'TCK-002341 · Poor quality',
      'Open',
      'Active',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.textContaining('Repeated no-shows'), findsOneWidget);
    await tester.tap(find.text('Ban'));
    await h.settle(tester);
    expect(
      find.text('Ban Nusrat Jahan? Their phone cannot register again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Repeated fake bookings'));
    await tester.tap(inDialog('Ban'));
    await h.settle(tester);
    expect(h.bodyOf(_status), {
      'status': 'banned',
      'reason': 'Repeated fake bookings',
    });
    expect(find.text('Banned'), findsWidgets);
    expect(find.text('Reinstate'), findsOneWidget);
    await tester.tap(find.text('TCK-002341 · Poor quality'));
    await h.settle(tester);
    expect(find.byType(ComplaintDetailPage), findsOneWidget);
  });

  testWidgets('read-only admins see no actions and no links', (tester) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester, screens: ['A09'], permissions: ['customer:read']);
    h.http
      ..onGet(_detail, (s) => s.reply(200, customerDetail(full: false)))
      ..onGet(_list, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.pumpApp(tester, _path);
    expect(find.text('No rating yet'), findsOneWidget);
    expect(find.text('No complaints yet.'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
    await tester.tap(find.text('All customers'));
    await h.settle(tester);
    expect(find.byType(CustomersPage), findsOneWidget);
  });

  testWidgets('a complaint row stays put without the complaints screen', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester, screens: ['A09', 'A10']);
    h.http.onGet(_detail, (s) => s.reply(200, customerDetail()));
    await h.pumpApp(tester, _path);
    await tester.tap(find.text('TCK-002341 · Poor quality'));
    await h.settle(tester);
    expect(find.byType(ComplaintDetailPage), findsNothing);
  });
}
