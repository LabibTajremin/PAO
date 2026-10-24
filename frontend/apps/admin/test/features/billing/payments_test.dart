import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/billing/presentation/ledger_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import '../providers/fixtures.dart';

const _list = '/v1/admin/billing/payments';
const _merchant = '33333333-3333-3333-3333-333333333333';
const _ledger = '/v1/admin/billing/merchants/$_merchant/ledger';

Map<String, Object?> _payment({String status = 'pending', String? reason}) => {
  'id': 'p1',
  'providerId': _merchant,
  'amount': 62000,
  'method': 'cash_to_agent',
  'reference': 'Agent Rahim',
  'status': status,
  'reason': ?reason,
  'createdAt': '2026-10-08T04:00:00Z',
  if (status != 'pending') 'reviewedAt': '2026-10-08T05:00:00Z',
};

Future<Harness> _open(WidgetTester tester, {List<String>? permissions}) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester, permissions: permissions);
  h.http.onGet(
    _list,
    (s) => s.reply(200, {
      'items': [_payment()],
    }),
  );
  await h.pumpApp(tester, Routes.payments);
  return h;
}

Future<void> _openRow(WidgetTester tester, Harness h) async {
  await tester.tap(find.text('Agent Rahim'));
  await h.settle(tester);
}

void main() {
  testWidgets('pending payments are listed first and filtered by status', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(find.text('Merchant payments'), findsOneWidget);
    expect(find.text('33333333'), findsOneWidget);
    expect(find.text('৳620'), findsOneWidget);
    expect(find.text('Cash to agent'), findsOneWidget);
    expect(h.sent.last.queryParameters['status'].toString(), 'pending');
    h.http.onGet(
      _list,
      (s) => s.reply(200, {
        'items': [_payment(status: 'rejected', reason: 'Not received')],
      }),
    );
    await choose(tester, h, 'Status: Pending', 'Any');
    expect(h.sent.last.queryParameters.containsKey('status'), isFalse);
    await _openRow(tester, h);
    expect(find.text('Not received'), findsOneWidget);
    expect(find.text('Confirm payment'), findsNothing);
    // Dismissed without a choice.
    await tester.tapAt(const Offset(5, 5));
    await h.settle(tester);
    expect(find.text('Not received'), findsNothing);
  });

  testWidgets('confirming credits the ledger; a decided one says so', (
    tester,
  ) async {
    final h = await _open(tester);
    h.http.onPost(
      '$_list/p1/confirm',
      (s) => s.reply(409, apiError('PAYMENT_NOT_PENDING')),
    );
    await _openRow(tester, h);
    await tester.tap(find.text('Confirm payment'));
    await h.settle(tester);
    expect(find.text('This payment has already been decided.'), findsOne);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    h.http.onPost(
      '$_list/p1/confirm',
      (s) => s.reply(200, _payment(status: 'confirmed')),
    );
    await _openRow(tester, h);
    await tester.tap(find.text('Confirm payment'));
    await h.settle(tester);
    expect(find.textContaining('Payment confirmed'), findsOneWidget);
  });

  testWidgets('rejecting needs a reason of 3 to 500 characters', (
    tester,
  ) async {
    final h = await _open(tester);
    await _openRow(tester, h);
    await tester.tap(find.text('Reject payment'));
    await h.settle(tester);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'POST'), isEmpty);
    await _openRow(tester, h);
    await tester.tap(find.text('Reject payment'));
    await h.settle(tester);
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'no');
    await tester.tap(find.text('Reject payment').last);
    await tester.pump();
    expect(find.textContaining('at least 3'), findsOneWidget);
    await tester.enterText(field, 'x' * 600);
    expect(tester.widget<TextField>(field).controller!.text, hasLength(500));
    await tester.enterText(field, 'No such transaction');
    h.http.onPost(
      '$_list/p1/reject',
      (s) => s.reply(200, _payment(status: 'rejected')),
      data: Matchers.any,
    );
    await tester.tap(find.text('Reject payment').last);
    await h.settle(tester);
    expect(h.bodyOf('$_list/p1/reject'), {'reason': 'No such transaction'});
    expect(find.textContaining('Payment rejected'), findsOneWidget);
  });

  testWidgets('the ledger shows the due and every entry', (tester) async {
    final h = await _open(tester);
    h.http.onGet(
      _ledger,
      (s) => s.reply(200, {
        'providerId': _merchant,
        'summary': {
          'due': 62000,
          'blockAmount': 50000,
          'blocked': true,
          'commissionRateBp': 1000,
          'pendingPayments': 62000,
        },
        'entries': {
          'items': [
            {
              'id': 'e1',
              'kind': 'commission',
              'amount': 11300,
              'bookingNumber': 'PAO-1',
              'jobTotal': 113000,
              'createdAt': '2026-10-08T04:00:00Z',
            },
            {
              'id': 'e2',
              'kind': 'payment',
              'amount': 20000,
              'createdAt': '2026-10-08T04:00:00Z',
            },
          ],
        },
      }),
    );
    await _openRow(tester, h);
    await tester.tap(find.text('View ledger'));
    await h.settle(tester);
    expect(find.byType(LedgerPage), findsOneWidget);
    expect(find.text('Blocked from accepting'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('Commission · PAO-1'), findsOneWidget);
    expect(find.text('+৳113'), findsOneWidget);
    expect(find.text('−৳200'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('without billing:manage the queue is hidden and denied', (
    tester,
  ) async {
    await _open(tester, permissions: const ['settings:read']);
    expect(find.byType(PaoAccessDeniedView), findsOneWidget);
    expect(find.text('Payments'), findsNothing);
  });
}
