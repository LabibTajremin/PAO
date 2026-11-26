import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';

import '../features/jobs/fixtures.dart' as jobs;
import '../features/profile/fixtures.dart';
import '../support/harness.dart';
import 'tour_support.dart';

/// Every signed-in screen of the tour and its location.
final Map<String, String> _screens = {
  'home': Routes.home,
  'jobs': Routes.jobs,
  'job': Routes.job(jobs.bookingId),
  'earnings': Routes.earnings,
  'profile': Routes.profile,
  'notifications': Routes.notifications,
  'orders': Routes.orders,
};

Map<String, Object?> _earned(String period) => {
  'period': period,
  'from': '2026-10-04',
  'to': '2026-10-10',
  'total': 226000,
  'jobs': 3,
  'buckets': [
    {'date': '2026-10-08', 'total': 113000, 'jobs': 1},
    {'date': '2026-10-09', 'total': 113000, 'jobs': 2},
  ],
};

void _reply(Harness h, String path, Object? body) =>
    h.http.onGet(path, (s) => s.reply(200, withBangla(body)));

Future<Harness> _signedIn(WidgetTester tester) async {
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      '/v1/provider/earnings/summary',
      (s) => s.replyCallback(
        200,
        (o) => _earned('${o.queryParameters['period']}'),
      ),
    )
    ..onGet(
      '/v1/provider/jobs',
      (s) => s.replyCallback(
        200,
        (o) => withBangla({
          'items': o.queryParameters['tab'] == 'requests'
              ? <Object>[]
              : [jobs.summary(), jobs.summary(id: 'b2', status: 'completed')],
        }),
      ),
    );
  _reply(h, '/v1/provider/jobs/${jobs.bookingId}', jobs.booking());
  _reply(h, '/v1/provider/earnings/jobs', {'items': <Object>[]});
  _reply(h, '/v1/provider/profile', profile());
  _reply(h, '/v1/provider/rating', rating());
  _reply(h, '/v1/provider/reviews', {
    'items': [review()],
  });
  _reply(h, '/v1/provider/notifications', {
    'items': [
      {
        'id': 'n1',
        'type': 'booking_requested',
        'title': 'New job nearby',
        'body': 'Fan repair in Banani, ৳1,130.',
        'bookingId': jobs.bookingId,
        'read': false,
        'createdAt': '2026-10-09T03:00:00Z',
      },
    ],
    'unreadCount': 1,
  });
  _reply(h, '/v1/provider/subscriptions', {'items': <Object>[]});
  _reply(h, '/v1/provider/deliveries', {'items': <Object>[]});
  return h;
}

Future<void> _look(Harness h, ThemeMode mode, String lang) async {
  await h.services.themeMode.select(mode);
  h.services.locale.select(Locale(lang));
}

void main() {
  setUpAll(loadTourFonts);

  for (final (mode, lang) in tourVariants) {
    final look = '${mode.name}_$lang';
    testWidgets('signed-in screens, $look', (tester) async {
      phone(tester);
      final h = await _signedIn(tester);
      await _look(h, mode, lang);
      await h.pumpApp(tester);
      for (final MapEntry(key: name, value: location) in _screens.entries) {
        await h.go(tester, location);
        await capture(tester, 'partner', '${name}_$look');
      }
    });

    testWidgets('signed-out screens, $look', (tester) async {
      phone(tester);
      final h = await Harness.create();
      await _look(h, mode, lang);
      await h.pumpApp(tester, Routes.onboarding);
      await capture(tester, 'partner', 'onboarding_$look');
      await h.go(tester, Routes.phone);
      await capture(tester, 'partner', 'sign_in_$look');
    });
  }
}
