import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_customer/features/notifications/data/push_registrar.dart';
import 'package:pao_customer/features/notifications/domain/notifications_repository.dart';
import 'package:pao_customer/features/notifications/domain/push_route.dart';

import '../../support/harness.dart';
import '../bookings/fixtures.dart';

class _Repo implements NotificationsRepository {
  final tokens = <String>[];
  bool fail = false;

  @override
  Future<Paged<Notification>> inbox({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<void> markRead(String id) => throw UnimplementedError();

  @override
  Future<void> markAllRead() => throw UnimplementedError();

  @override
  Future<void> registerDevice(String token) async {
    if (fail) throw const NetworkFailure();
    tokens.add(token);
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('push data maps to the screen it is about (C60)', () {
    final routes = {
      for (final type in [
        'booking_accepted',
        'provider_on_the_way',
        'provider_arrived',
        'booking_started',
      ])
        type: Routes.booking('b1', 'live'),
      'extras_proposed': Routes.booking('b1', 'extras'),
      'booking_completed': Routes.booking('b1', 'completed'),
      'booking_cancelled': Routes.booking('b1'),
      'booking_timed_out': Routes.booking('b1'),
    };
    for (final MapEntry(key: type, value: route) in routes.entries) {
      expect(pushRoute({'bookingId': 'b1', 'type': type}), route, reason: type);
    }
    expect(pushRoute({'bookingId': '', 'type': 7}), Routes.notifications);
    expect(pushRoute({'type': 'promo'}), Routes.notifications);
  });

  test('the registrar follows the session, refreshes and taps', () async {
    final sessions = SessionManager(MemorySessionStore());
    final push = FakePush();
    final repo = _Repo();
    final opened = <String>[];
    final registrar = PushRegistrar(
      sessions: sessions,
      push: push,
      repo: repo,
      open: opened.add,
    )..start();
    push.refreshes.add('ignored-signed-out');
    await _flush();
    expect(repo.tokens, isEmpty);
    await sessions.signIn(const Session(accessToken: 'a'));
    await _flush();
    expect(repo.tokens, ['device-token']);
    await sessions.signIn(const Session(accessToken: 'a2'));
    push.refreshes.add('refreshed-token');
    push.taps.add({'bookingId': 'b9', 'type': 'provider_arrived'});
    await _flush();
    expect(repo.tokens, ['device-token', 'refreshed-token']);
    expect(opened, [Routes.booking('b9', 'live')]);
    await sessions.signOut();
    push.value = null;
    await sessions.signIn(const Session(accessToken: 'b'));
    repo.fail = true;
    push.refreshes.add('failing-token');
    await _flush();
    expect(repo.tokens, hasLength(2));
    await registrar.stop();
    push.taps.add({'type': 'booking_cancelled'});
    await _flush();
    expect(opened, hasLength(1));
  });

  testWidgets('the app registers the device and opens tapped bookings', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http
      ..onPut('/v1/customer/device-token', (s) => s.reply(204, null))
      ..onGet(
        '/v1/customer/bookings/$bookingId',
        (s) => s.reply(200, booking(status: 'cancelled')),
      );
    await h.pumpApp(tester);
    expect(h.bodyOf('/v1/customer/device-token'), {
      'token': 'device-token',
      'platform': 'android',
    });
    h.push.taps.add({'bookingId': bookingId, 'type': 'booking_cancelled'});
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });
}
