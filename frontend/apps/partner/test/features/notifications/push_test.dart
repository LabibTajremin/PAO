import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/notifications/data/push_registrar.dart';
import 'package:pao_partner/features/notifications/domain/notifications_repository.dart';
import 'package:pao_partner/features/notifications/domain/push_route.dart';
import 'package:pao_partner/features/requests/presentation/request_page.dart';

import '../../support/harness.dart';
import '../job/job_fixtures.dart';

class _Repo implements NotificationsRepository {
  final tokens = <String>[];
  bool fail = false;

  @override
  Future<NotificationList> inbox() => throw UnimplementedError();

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
  test('push data maps to the screen it is about', () {
    expect(
      pushRoute({'bookingId': 'b1', 'type': 'booking_requested'}),
      Routes.requestOf('b1'),
    );
    expect(
      pushRoute({'bookingId': 'b1', 'type': 'request_missed'}),
      Routes.requestOf('b1'),
    );
    expect(
      pushRoute({'bookingId': 'b1', 'type': 'booking_cancelled'}),
      Routes.job('b1', 'live'),
    );
    expect(
      pushRoute({'type': 'document_expiring'}),
      Routes.profilePage('documents'),
    );
    expect(pushRoute({'type': 'level_changed'}), Routes.profilePage('level'));
    expect(pushRoute({'bookingId': '', 'type': 7}), Routes.notifications);
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
    expect(opened, [Routes.job('b9', 'live')]);
    await sessions.signOut();
    push.value = null;
    await sessions.signIn(const Session(accessToken: 'b'));
    repo.fail = true;
    push.refreshes.add('failing-token');
    await _flush();
    expect(repo.tokens, hasLength(2));
    await registrar.stop();
    push.taps.add({'type': 'level_changed'});
    await _flush();
    expect(opened, hasLength(1));
  });

  testWidgets('the app registers the device and opens tapped requests', (
    tester,
  ) async {
    tallScreen(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http
      ..onPut('/v1/provider/device-token', (s) => s.reply(204, null))
      ..onGet(
        '/v1/provider/jobs/b1',
        (s) => s.reply(200, booking(status: 'requested')),
      );
    await h.pumpApp(tester, Routes.notifications);
    expect(h.bodyOf('/v1/provider/device-token'), {
      'token': 'device-token',
      'platform': 'android',
    });
    h.push.taps.add({'bookingId': 'b1', 'type': 'booking_requested'});
    await h.settle(tester);
    expect(find.byType(RequestPage), findsOneWidget);
  });
}
