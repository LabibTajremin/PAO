import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/billing/presentation/billing_page.dart';
import 'package:pao_partner/features/billing/presentation/pay_page.dart';
import 'package:pao_partner/features/home/presentation/home_page.dart';

import '../../support/harness.dart';
import '../job/job_fixtures.dart';
import 'billing_fixtures.dart';

const _job = '/v1/provider/jobs/b1';

Future<Harness> _home(WidgetTester tester, Map<String, Object?> json) async {
  tallScreen(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(dueUrl, (s) => s.reply(200, json))
    ..onGet(
      '/v1/provider/earnings/summary',
      (s) => s.reply(200, {
        'period': 'day',
        'from': '2026-10-09',
        'to': '2026-10-09',
        'total': 0,
        'jobs': 0,
        'buckets': <Object?>[],
      }),
    )
    ..onGet('/v1/provider/jobs', (s) => s.reply(200, {'items': <Object?>[]}))
    ..onGet(ledgerUrl, (s) => s.reply(200, {'items': <Object?>[]}))
    ..onGet(paymentsUrl, (s) => s.reply(200, {'items': <Object?>[]}));
  await h.pumpApp(tester);
  return h;
}

void main() {
  testWidgets('a blocked merchant sees the due and can pay from home', (
    tester,
  ) async {
    final h = await _home(tester, due());
    expect(
      find.text('Due ৳620 is over the ৳500 limit. Pay to accept new jobs.'),
      findsOneWidget,
    );
    // Offers keep arriving while blocked.
    expect(find.text('No requests right now'), findsOneWidget);
    await tester.tap(find.text('Pay now'));
    await h.settle(tester);
    expect(find.byType(PayPage), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.textContaining('Due ৳620'));
    await h.settle(tester);
    expect(find.byType(BillingPage), findsOneWidget);
  });

  testWidgets('near the limit warns', (tester) async {
    await _home(tester, due(amount: 45000));
    expect(find.text('Due ৳450 is close to the ৳500 limit.'), findsOneWidget);
  });

  testWidgets('far below the limit shows nothing', (tester) async {
    await _home(tester, due(amount: 100));
    expect(find.textContaining('limit'), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('accepting while blocked explains the due and links to pay', (
    tester,
  ) async {
    tallScreen(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(
        _job,
        (s) => s.reply(
          200,
          booking(status: 'requested', party: null, located: false),
        ),
      )
      ..onPost(
        '$_job/accept',
        (s) => s.reply(409, apiError('MERCHANT_DUE_LIMIT')),
      );
    await h.pumpApp(tester, Routes.requestOf('b1'));
    await tester.tap(find.text('Accept'));
    await h.settle(tester);
    expect(find.textContaining('PAO due is over the limit'), findsOneWidget);
    await tester.tap(find.text('Pay now'));
    await h.settle(tester);
    expect(find.byType(PayPage), findsOneWidget);
  });
}
