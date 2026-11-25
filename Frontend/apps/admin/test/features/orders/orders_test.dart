import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_admin/features/orders/order_detail_page.dart';
import 'package:pao_admin/features/orders/order_labels.dart';
import 'package:pao_admin/features/orders/orders_page.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';

import '../../support/harness.dart';
import '../bookings/fixtures.dart';
import '../providers/fixtures.dart';

const _list = '/v1/admin/subscriptions';

Map<String, Object?> _order({String status = 'active'}) => {
  'id': 'o1',
  'number': 'PAO-S-500001',
  'status': status,
  'serviceId': 's1',
  'serviceName': {'en': 'Office lunch', 'bn': 'অফিস লাঞ্চ'},
  'customer': {'id': 'c1', 'name': 'Nusrat', 'phone': '+8801812345602'},
  'provider': {'id': 'p1', 'name': 'Ayesha'},
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
      'status': 'delivered',
      'items': <Object>[],
      'total': 36000,
      'bookingId': bookingId,
    },
    {
      'date': '2026-10-12',
      'status': 'scheduled',
      'items': <Object>[],
      'total': 36000,
    },
  ],
};

void main() {
  testWidgets('support filters orders, opens one and its booked dates', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet('/v1/admin/bookings', (s) => s.reply(200, {'items': <Object>[]}))
      ..onGet(
        _list,
        (s) => s.reply(200, {
          'items': [_order()],
        }),
      )
      ..onGet(
        _list,
        (s) => s.reply(200, {'items': <Object>[]}),
        queryParameters: {'status': 'paused'},
      )
      ..onGet('$_list/o1', (s) => s.reply(200, _order()))
      ..onGet('/v1/admin/bookings/$bookingId', (s) => s.reply(200, booking()));
    await h.pumpApp(tester, Routes.bookings);
    await tester.tap(find.text('Scheduled orders'));
    await h.settle(tester);
    expect(find.byType(OrdersPage), findsOneWidget);
    expect(find.text('PAO-S-500001 · Office lunch'), findsOneWidget);
    await tester.tap(find.text('Paused').first);
    await h.settle(tester);
    expect(find.text('No scheduled orders'), findsOneWidget);
    await tester.tap(find.text('All'));
    await h.settle(tester);
    await tester.tap(find.text('PAO-S-500001 · Office lunch'));
    await h.settle(tester);
    expect(find.byType(OrderDetailPage), findsOneWidget);
    expect(find.text('Nusrat · +8801812345602'), findsOneWidget);
    await tester.tap(find.text('Scheduled'));
    await h.settle(tester);
    expect(find.byType(OrderDetailPage), findsOneWidget);
    await tester.tap(find.text('Delivered'));
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  test('every status has words in both languages', () {
    for (final locale in ['en', 'bn']) {
      final t = lookupAdminL10n(Locale(locale));
      for (final s in SubscriptionStatus.values) {
        expect(subscriptionStatus(t, s).$1, isNotEmpty);
      }
      for (final s in DeliveryStatus.values) {
        expect(deliveryStatus(t, s), isNotEmpty);
      }
    }
  });
}
