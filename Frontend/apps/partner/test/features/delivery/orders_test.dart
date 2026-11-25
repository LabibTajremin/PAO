import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_partner/features/delivery/presentation/order_page.dart';
import 'package:pao_partner/features/delivery/presentation/orders_page.dart';
import 'package:pao_partner/features/jobs/presentation/job_detail_page.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';

import '../../support/harness.dart';
import '../jobs/fixtures.dart';

const _path = '/v1/provider/subscriptions/o1';
const _lunch = {'en': 'Office lunch', 'bn': 'অফিস লাঞ্চ'};

Map<String, Object?> _order({
  String status = 'requested',
  bool changeable = true,
}) => {
  'id': 'o1',
  'number': 'PAO-S-500001',
  'status': status,
  'serviceId': 's1',
  'serviceName': _lunch,
  'customer': {'id': 'c1', 'name': 'Nusrat'},
  'items': <Object>[],
  'total': 36000,
  'pattern': 'weekdays',
  'window': {'start': '12:00', 'end': '13:00'},
  'startDate': '2026-10-11',
  'address': {'area': 'Banani', 'line1': 'House 12'},
  'createdAt': '2026-10-09T04:00:00Z',
  'upcoming': [
    {
      'date': '2026-10-11',
      'status': 'scheduled',
      'items': <Object>[],
      'total': 36000,
      'changeable': changeable,
    },
    {
      'date': '2026-10-12',
      'status': 'skipped',
      'items': <Object>[],
      'total': 36000,
      'changeable': false,
    },
  ],
};

Map<String, Object?> _delivery(
  String date, {
  String? bookingId,
  String status = 'scheduled',
}) => {
  'subscriptionId': 'o1',
  'number': 'PAO-S-500001',
  'date': date,
  'window': {'start': '12:00', 'end': '13:00'},
  'status': status,
  'serviceName': _lunch,
  'items': <Object>[],
  'total': 36000,
  'address': {'area': 'Banani'},
  'customerName': 'Nusrat',
  'bookingId': ?bookingId,
};

Future<Harness> _open(
  WidgetTester tester, {
  List<Object> orders = const [],
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      '/v1/provider/subscriptions',
      (s) => s.reply(200, {'items': orders}),
      queryParameters: {'status': 'requested'},
    )
    ..onGet(_path, (s) => s.reply(200, _order()))
    ..onGet(
      '/v1/provider/jobs',
      (s) => s.reply(200, {'items': <Object>[]}),
      queryParameters: {'tab': 'upcoming'},
    );
  await h.pumpApp(tester, Routes.jobs);
  await tester.tap(find.byIcon(Icons.event_repeat_outlined));
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('a new order is accepted, or declined with a reason', (
    tester,
  ) async {
    final h = await _open(tester, orders: [_order()]);
    expect(find.byType(OrdersPage), findsOneWidget);
    expect(find.text('Chosen days · 12:00–13:00 · Banani'), findsOneWidget);
    await tester.tap(find.text('Office lunch'));
    await h.settle(tester);
    expect(find.byType(OrderPage), findsOneWidget);
    expect(find.text('Nusrat · Banani · House 12'), findsOneWidget);
    h.http.onPost(
      '$_path/accept',
      (s) => s.reply(409, apiError('MERCHANT_DUE_LIMIT')),
    );
    await tester.tap(find.text('Accept order'));
    await h.settle(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(find.text('Decline').first);
    await h.settle(tester);
    await tester.tap(find.text('Too far away'));
    await tester.pump();
    h.http.onPost(
      '$_path/decline',
      (s) => s.reply(200, _order(status: 'declined')),
    );
    await tester.tap(find.text('Decline').last);
    await h.settle(tester);
    expect(h.bodyOf('$_path/decline'), {'reason': 'too_far'});
  });

  testWidgets(
    'a date is declined before its cutoff and a dismissed sheet does nothing',
    (tester) async {
      final h = await _open(tester, orders: [_order()]);
      await tester.tap(find.text('Office lunch'));
      await h.settle(tester);
      await tester.tap(find.text('Decline').first);
      await h.settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await h.settle(tester);
      h.http.onPost(
        '$_path/deliveries/2026-10-11/decline',
        (s) => s.reply(200, {
          'date': '2026-10-11',
          'status': 'declined',
          'items': <Object>[],
          'total': 0,
        }),
      );
      h.http.onGet(
        _path,
        (s) => s.reply(200, _order(status: 'active', changeable: false)),
      );
      await tester.tap(find.text("Can't deliver"));
      await h.settle(tester);
      expect(find.text("Can't deliver"), findsNothing);
      expect(find.text('Accept order'), findsNothing);
    },
  );

  testWidgets('the week lists deliveries; a booked one opens its job', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(find.text('No new orders'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/deliveries',
      (s) => s.reply(200, {'items': <Object>[]}),
      queryParameters: {'from': '2026-10-09', 'to': '2026-10-15'},
    );
    await tester.tap(find.text('This week'));
    await h.settle(tester);
    expect(find.text('No deliveries this week'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/deliveries',
      (s) => s.reply(200, {
        'items': [
          _delivery('2026-10-11'),
          _delivery('2026-10-12', bookingId: bookingId, status: 'preparing'),
        ],
      }),
      queryParameters: {'from': '2026-10-09', 'to': '2026-10-15'},
    );
    await tester.tap(find.text('New orders'));
    await h.settle(tester);
    await tester.tap(find.text('This week'));
    await h.settle(tester);
    expect(find.text('Prepare today'), findsOneWidget);
    await tester.tap(find.textContaining('Sun, 11 Oct'));
    await h.settle(tester);
    expect(find.byType(OrderPage), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    h.http.onGet(
      '/v1/provider/jobs/$bookingId',
      (s) => s.reply(200, booking()),
    );
    await tester.tap(find.textContaining('Mon, 12 Oct'));
    await h.settle(tester);
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  test('every order and delivery status has words in both languages', () {
    for (final locale in ['en', 'bn']) {
      final t = lookupPartnerL10n(Locale(locale));
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
