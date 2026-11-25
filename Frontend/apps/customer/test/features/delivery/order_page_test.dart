import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/features/booking/presentation/setup_page.dart';
import 'package:pao_customer/features/delivery/presentation/order_page.dart';
import 'package:pao_customer/features/delivery/presentation/subscription_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import '../booking/booking_fixtures.dart';
import 'delivery_fixtures.dart';

const _order = '/book?service=s1&items=x1:2&provider=p1&delivery=1';

Future<Harness> _open(WidgetTester tester, {bool fail = false}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      '/v1/customer/services/s1',
      (s) => fail
          ? s.reply(500, apiError('INTERNAL'))
          : s.reply(200, scheduledService()),
    )
    ..onGet('/v1/customer/providers/p1', (s) => s.reply(200, providerProfile))
    ..onGet(
      '/v1/customer/addresses',
      (s) => s.reply(200, {
        'items': [
          address('a2', label: 'office'),
          address('a1', isDefault: true),
        ],
      }),
    )
    ..onGet(
      '/v1/customer/subscriptions/o1',
      (s) => s.reply(200, subscription()),
    );
  await h.pumpApp(tester, _order);
  return h;
}

Future<void> _tap(Harness h, WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await h.settle(tester);
}

void main() {
  testWidgets(
    'weekday lunch is ordered with the chosen days, window and count',
    (tester) async {
      final h = await _open(tester);
      expect(find.byType(OrderPage), findsOneWidget);
      expect(find.text('Chosen days'), findsOneWidget);
      expect(find.text('Item x1 × 2'), findsOneWidget);
      await _tap(h, tester, 'Thu');
      await _tap(h, tester, 'Sat');
      await _tap(h, tester, '13:00–14:00');
      await _tap(h, tester, 'Office · Banani');
      await tester.tap(find.byIcon(Icons.add).last);
      await h.settle(tester);
      await tester.enterText(find.byType(TextField), ' Reception ');
      h.http.onPost(
        '/v1/customer/subscriptions',
        (s) => s.reply(500, apiError('INTERNAL')),
      );
      await _tap(h, tester, 'Place order');
      expect(
        find.text('Our service had a problem. Please try again.'),
        findsOneWidget,
      );
      final first = h.sent.last.headers['Idempotency-Key'];
      h.http.onPost(
        '/v1/customer/subscriptions',
        (s) => s.reply(201, subscription(status: 'requested')),
      );
      await _tap(h, tester, 'Place order');
      expect(
        h.sent
            .lastWhere(
              (o) =>
                  o.path == '/v1/customer/subscriptions' && o.method == 'POST',
            )
            .headers['Idempotency-Key'],
        first,
      );
      expect(h.bodyOf('/v1/customer/subscriptions'), {
        'providerId': 'p1',
        'serviceId': 's1',
        'items': [
          {'subServiceId': 'x1', 'quantity': 2},
        ],
        'addressId': 'a2',
        'pattern': 'weekdays',
        'weekdays': [0, 1, 2, 3, 6],
        'window': {'start': '13:00', 'end': '14:00'},
        'startDate': '2026-10-10',
        'count': 11,
        'note': 'Reception',
      });
      expect(find.byType(SubscriptionPage), findsOneWidget);
    },
  );

  testWidgets('one-time, weekly and monthly orders ask only what they need', (
    tester,
  ) async {
    final h = await _open(tester);
    await _tap(h, tester, 'One time');
    expect(find.text('Days'), findsNothing);
    expect(find.text('Number of deliveries'), findsNothing);
    await _tap(h, tester, 'Once a week');
    await _tap(h, tester, 'Mon');
    await _tap(h, tester, 'Once a month');
    expect(find.text('Day of the month'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add).first);
    await h.settle(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await h.settle(tester);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await h.settle(tester);
    h.http.onPost(
      '/v1/customer/subscriptions',
      (s) => s.reply(201, subscription()),
    );
    await _tap(h, tester, 'Place order');
    final body = h.bodyOf('/v1/customer/subscriptions')! as Map;
    expect(
      (
        body['pattern'],
        body['dayOfMonth'],
        body['startDate'],
        body['weekdays'],
      ),
      ('monthly', 10, '2026-10-20', null),
    );
  });

  testWidgets('a cancelled date pick changes nothing and load failures retry', (
    tester,
  ) async {
    final h = await _open(tester, fail: true);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(
      '/v1/customer/services/s1',
      (s) => s.reply(200, scheduledService()),
    );
    await _tap(h, tester, 'Try again');
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await h.settle(tester);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.textContaining('Oct 10'), findsOneWidget);
    await h.go(tester, '/book?service=s1&items=x1:2&delivery=1');
    expect(find.byType(SetupPage), findsOneWidget);
    expect(find.byType(PaoButton), findsWidgets);
  });
}
