import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/billing/presentation/billing_page.dart';
import 'package:pao_partner/features/billing/presentation/pay_page.dart';

import '../../support/harness.dart';
import '../job/job_fixtures.dart';
import 'billing_fixtures.dart';

Future<Harness> _open(WidgetTester tester, String route) async {
  tallScreen(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(dueUrl, (s) => s.reply(200, due(pending: 20000, rate: 1050)))
    ..onGet(
      ledgerUrl,
      (s) => s.replyCallback(
        200,
        (o) => o.queryParameters['cursor'] == null
            ? {
                'items': [entry(), entry(commission: false)],
                'nextCursor': 'c2',
              }
            : {
                'items': [entry(number: 'PAO-9')],
              },
      ),
    )
    ..onGet(
      paymentsUrl,
      (s) => s.reply(200, {
        'items': [
          payment(),
          payment(status: 'rejected', reason: 'No such txn', reference: 'B'),
          payment(status: 'confirmed', reference: 'C'),
        ],
      }),
    );
  await h.pumpApp(tester, route);
  return h;
}

void main() {
  testWidgets('shows the due, the ledger and the payment history', (
    tester,
  ) async {
    final h = await _open(tester, Routes.billing);
    expect(find.text('৳620'), findsOneWidget);
    expect(find.text('Limit ৳500'), findsOneWidget);
    expect(find.text('Commission 10.50% of each completed job'), findsOne);
    expect(find.text('Waiting for confirmation: ৳200'), findsOneWidget);
    expect(find.textContaining("can't accept new jobs"), findsOneWidget);
    expect(find.text('Commission · PAO-1'), findsOneWidget);
    expect(find.text('+৳113'), findsOneWidget);
    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('−৳200'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Commission · PAO-9'), findsOneWidget);
    await tester.tap(find.text('Payments'));
    await h.settle(tester);
    expect(find.text('bKash · Pending'), findsOneWidget);
    expect(find.text('bKash · Rejected'), findsOneWidget);
    expect(find.text('bKash · Confirmed'), findsOneWidget);
    expect(find.textContaining('Rejected: No such txn'), findsOneWidget);
  });

  testWidgets('empty histories explain themselves', (tester) async {
    final h = await _open(tester, Routes.home);
    h.http
      ..onGet(dueUrl, (s) => s.reply(200, due(amount: 0)))
      ..onGet(ledgerUrl, (s) => s.reply(200, {'items': <Object?>[]}))
      ..onGet(paymentsUrl, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.go(tester, Routes.billing);
    expect(find.text('No entries yet'), findsOneWidget);
    await tester.tap(find.text('Payments'));
    await h.settle(tester);
    expect(find.text('No payments yet'), findsOneWidget);
  });

  testWidgets('paying validates, reports and returns to billing', (
    tester,
  ) async {
    final h = await _open(tester, Routes.billing);
    await tester.tap(find.text('Pay now'));
    await h.settle(tester);
    expect(find.byType(PayPage), findsOneWidget);
    await tester.tap(find.text('Submit payment'));
    await tester.pump();
    expect(find.textContaining('Enter an amount'), findsOneWidget);
    expect(find.text('Choose how you paid.'), findsOneWidget);
    expect(find.textContaining('Enter a reference'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '620');
    await tester.enterText(find.byType(TextField).last, 'TX77');
    await tester.tap(find.text('Nagad'));
    await tester.pump();
    h.http.onPost(
      paymentsUrl,
      (s) => s.reply(409, apiError('VALIDATION_FAILED')),
      data: Matchers.any,
    );
    await tester.tap(find.text('Submit payment'));
    await h.settle(tester);
    expect(find.byType(PayPage), findsOneWidget);
    h.http.onPost(
      paymentsUrl,
      (s) => s.reply(201, payment(reference: 'TX77')),
      data: Matchers.any,
    );
    await tester.tap(find.text('Submit payment'));
    await h.settle(tester);
    final post = h.sent.lastWhere((o) => o.method == 'POST');
    expect(jsonDecode(post.data as String), {
      'amountPaisa': 62000,
      'method': 'nagad',
      'reference': 'TX77',
    });
    expect(find.byType(BillingPage), findsOneWidget);
    expect(find.textContaining('Payment submitted'), findsOneWidget);
  });
}
