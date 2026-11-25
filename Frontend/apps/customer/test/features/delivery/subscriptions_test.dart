import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_customer/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_customer/features/delivery/presentation/subscription_page.dart';
import 'package:pao_customer/features/delivery/presentation/subscriptions_page.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';

import '../../support/harness.dart';
import '../booking/booking_fixtures.dart';
import 'delivery_fixtures.dart';

const _path = '/v1/customer/subscriptions/o1';

Future<Harness> _open(
  WidgetTester tester,
  List<Map<String, Object?>> list,
) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet('/v1/customer/subscriptions', (s) => s.reply(200, {'items': list}))
    ..onGet(_path, (s) => s.reply(200, subscription()))
    ..onGet(
      '/v1/customer/bookings',
      (s) => s.reply(200, {'items': <Object>[]}),
      queryParameters: {'tab': 'upcoming'},
    );
  await h.pumpApp(tester, '/bookings');
  await tester.tap(find.byIcon(Icons.event_repeat_outlined));
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('without orders the list says so', (tester) async {
    await _open(tester, []);
    expect(find.byType(SubscriptionsPage), findsOneWidget);
    expect(find.text('No scheduled orders yet'), findsOneWidget);
  });

  testWidgets(
    'an order shows its dates and skips, pauses, resumes and cancels',
    (tester) async {
      final h = await _open(tester, [subscription()]);
      expect(
        find.text('Chosen days · 12:00–13:00 · PAO-S-500001'),
        findsOneWidget,
      );
      await tester.tap(find.text('Fan repair'));
      await h.settle(tester);
      expect(find.byType(SubscriptionPage), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);
      h.http.onPut(
        '$_path/deliveries/2026-10-12',
        (s) => s.reply(200, deliveryDate('2026-10-12', status: 'skipped')),
        data: {'skip': true},
      );
      await tester.tap(find.text('Skip'));
      await h.settle(tester);
      expect(h.bodyOf('$_path/deliveries/2026-10-12'), {'skip': true});
      h.http.onPut(
        '$_path/deliveries/2026-10-13',
        (s) => s.reply(409, apiError('DELIVERY_CUTOFF_PASSED')),
        data: {'skip': false},
      );
      await tester.tap(find.text('Bring back'));
      await h.settle(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      for (final (button, move, status) in [
        ('Pause', 'pause', 'paused'),
        ('Resume', 'resume', 'active'),
        ('Cancel order', 'cancel', 'cancelled'),
      ]) {
        h.http.onPost(
          '$_path/$move',
          (s) => s.reply(200, subscription(status: status)),
        );
        h.http.onGet(_path, (s) => s.reply(200, subscription(status: status)));
        await tester.ensureVisible(find.text(button));
        await tester.tap(find.text(button));
        await h.settle(tester);
        expect(h.sent.last.path, _path);
      }
      expect(find.text('Cancel order'), findsNothing);
    },
  );

  testWidgets(
    'a delivered date opens its booking and a requested order can be cancelled',
    (tester) async {
      final h = await _open(tester, [subscription(status: 'requested')]);
      h.http.onGet(
        _path,
        (s) => s.reply(200, subscription(status: 'requested')),
      );
      await tester.tap(find.text('Fan repair'));
      await h.settle(tester);
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Cancel order'), findsOneWidget);
      h.http.onGet('/v1/customer/bookings/b1', (s) => s.reply(200, booking()));
      await tester.tap(find.textContaining('Oct 11'));
      await h.settle(tester);
      expect(find.byType(BookingDetailPage), findsOneWidget);
    },
  );

  test('every order and delivery status has words in both languages', () {
    for (final locale in ['en', 'bn']) {
      final t = lookupCustomerL10n(Locale(locale));
      for (final s in SubscriptionStatus.values) {
        expect(subscriptionStatus(t, s).$1, isNotEmpty);
      }
      for (final s in DeliveryStatus.values) {
        expect(deliveryStatus(t, s).$1, isNotEmpty);
      }
      for (final p in DeliveryPattern.values) {
        expect(patternLabel(t, p), isNotEmpty);
      }
    }
  });
}
