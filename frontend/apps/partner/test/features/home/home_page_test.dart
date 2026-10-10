import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/home/data/prefs_online_memory.dart';
import 'package:pao_partner/features/notifications/presentation/notifications_page.dart';
import 'package:pao_partner/features/profile/presentation/documents_page.dart';
import 'package:pao_partner/features/requests/presentation/request_page.dart';

import '../../support/harness.dart';
import '../job/job_fixtures.dart';

const _earnings = '/v1/provider/earnings/summary';
const _jobs = '/v1/provider/jobs';

Map<String, Object?> _today({int total = 150000, int jobs = 2}) => {
  'period': 'day',
  'from': '2026-10-09',
  'to': '2026-10-09',
  'total': total,
  'jobs': jobs,
  'buckets': <Object?>[],
};

Future<Harness> _home(
  WidgetTester tester, {
  List<Map<String, Object?>> requests = const [],
  List<Map<String, Object?>> jobs = const [],
  bool online = false,
}) async {
  tallScreen(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  await h.services.prefs.setFlag(PrefsOnlineMemory.key, value: online);
  h.http
    ..onGet(_earnings, (s) => s.reply(200, _today()))
    ..onGet(
      _jobs,
      (s) => s.reply(
        200,
        (RequestOptions o) => {
          'items': o.queryParameters['tab'] == 'requests' ? requests : jobs,
        },
      ),
    )
    ..onPost(
      '/v1/provider/presence/online',
      (s) => s.reply(200, {'online': true}),
    )
    ..onPost(
      '/v1/provider/presence/offline',
      (s) => s.reply(200, {'online': false}),
    )
    ..onPost(
      '/v1/provider/presence/heartbeat',
      (s) => s.reply(200, {'online': true}),
    );
  await h.pumpApp(tester);
  return h;
}

int _count(Harness h, String path) =>
    h.sent.where((o) => o.path == path).length;

void main() {
  testWidgets('shows earnings, the active job and open requests', (
    tester,
  ) async {
    final h = await _home(
      tester,
      requests: [summary(id: 'r1')],
      jobs: [
        summary(id: 'j1', status: 'accepted'),
        summary(id: 'j2', status: 'in_progress'),
      ],
    );
    expect(find.text('৳1,500'), findsOneWidget);
    expect(find.text('2 jobs today'), findsOneWidget);
    expect(find.text('Job started · Nusrat'), findsOneWidget);
    expect(find.text('Waiting for your answer · Nusrat'), findsOneWidget);
    h.http.onGet(
      '$_jobs/r1',
      (s) => s.reply(200, booking(status: 'requested')),
    );
    await tester.tap(find.text('Waiting for your answer · Nusrat'));
    await h.settle(tester);
    expect(find.byType(RequestPage), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    expect(_count(h, _earnings), 2);
  });

  testWidgets('going online sends the position and heartbeats until offline', (
    tester,
  ) async {
    final h = await _home(tester);
    expect(find.text('No requests right now'), findsOneWidget);
    expect(find.text('You are offline'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await h.settle(tester);
    expect(find.text('You are online'), findsOneWidget);
    expect(h.bodyOf('/v1/provider/presence/online'), {
      'location': {'lat': 23.794, 'lng': 90.407},
    });
    await tester.pump(const Duration(seconds: 30));
    await h.settle(tester);
    expect(_count(h, '/v1/provider/presence/heartbeat'), 1);
    await tester.tap(find.byType(Switch));
    await h.settle(tester);
    expect(find.text('You are offline'), findsOneWidget);
    expect(_count(h, '/v1/provider/presence/offline'), 1);
    expect(h.services.prefs.flag(PrefsOnlineMemory.key), isFalse);
  });

  testWidgets('location off keeps the provider offline', (tester) async {
    final h = await _home(tester);
    h.location.point = null;
    await tester.tap(find.byType(Switch));
    await h.settle(tester);
    expect(
      find.text(
        'Turn on location to go online. It is shared only while you are '
        'online.',
      ),
      findsOneWidget,
    );
    expect(_count(h, '/v1/provider/presence/online'), 0);
  });

  testWidgets('a refused switch explains why', (tester) async {
    final h = await _home(tester);
    h.http.onPost(
      '/v1/provider/presence/online',
      (s) => s.reply(409, apiError('NOT_VERIFIED')),
    );
    await tester.tap(find.byType(Switch));
    await h.settle(tester);
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Your verification is not complete yet.'), findsOneWidget);
    expect(_count(h, '/v1/provider/presence/online'), 1);
  });

  testWidgets('a provider who was online goes back online', (tester) async {
    final h = await _home(tester, online: true);
    expect(find.text('You are online'), findsOneWidget);
    expect(_count(h, '/v1/provider/presence/online'), 1);
    await h.go(tester, Routes.notifications);
  });

  testWidgets('a failed load can be retried and pulled to refresh', (
    tester,
  ) async {
    final h = await _home(tester);
    h.http.onGet(_earnings, (s) => s.reply(503, apiError('INTERNAL')));
    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await h.settle(tester);
    expect(_count(h, _earnings), 2);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http.onGet(_earnings, (s) => s.reply(200, _today(total: 0, jobs: 1)));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('1 job today'), findsOneWidget);
  });

  testWidgets('an expired document pauses requests (M15b)', (tester) async {
    final h = await _home(tester);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(200, {
        ...verification(),
        'items': [
          {
            'type': 'police_clearance',
            'status': 'expired',
            'required': true,
            'expiresAt': '2026-10-20T00:00:00Z',
          },
        ],
      }),
    );
    await tester.runAsync(h.services.gate.load);
    await tester.pump();
    expect(find.text('Requests paused'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(
      find.text(
        'A document expires on 20 Oct 2026. Renew it to keep receiving '
        'requests.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Renew document'));
    await h.settle(tester);
    expect(find.byType(DocumentsPage), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.textContaining('A document expires on'));
    await h.settle(tester);
    expect(find.byType(DocumentsPage), findsOneWidget);
  });

  testWidgets('the bell opens the inbox', (tester) async {
    final h = await _home(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await h.settle(tester);
    expect(find.byType(NotificationsPage), findsOneWidget);
  });
}
