import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';

import '../features/bookings/fixtures.dart' as bookings;
import '../features/location/fixtures.dart';
import '../features/providers/fixtures.dart';
import '../features/service/fixtures.dart';
import '../support/harness.dart';
import 'tour_support.dart';

/// Every signed-in screen of the tour and its location.
final Map<String, String> _screens = {
  'home': Routes.home,
  'services': Routes.services,
  'service': Routes.serviceOf(electricianId),
  'providers': Routes.providersOf(electricianId),
  'provider': Routes.providerOf(rahimId),
  'bookings': Routes.bookings,
  'booking': Routes.booking(bookings.bookingId),
  'notifications': Routes.notifications,
  'account': Routes.account,
  'addresses': Routes.accountPage('addresses'),
  'language': Routes.accountPage('language'),
  'subscriptions': Routes.subscriptions,
};

void _reply(Harness h, String path, Object? body) =>
    h.http.onGet(path, (s) => s.reply(200, withBangla(body)));

Future<Harness> _signedIn(WidgetTester tester) async {
  final h = await Harness.create();
  await h.signIn(tester);
  _reply(h, '/v1/customer/addresses', addressList([address()]));
  _reply(h, '/v1/customer/catalog', catalog());
  _reply(h, '/v1/customer/service-area', coverage());
  _reply(h, '/v1/customer/banners', {'items': <Object>[]});
  _reply(h, '/v1/customer/services/$electricianId', service());
  _reply(
    h,
    '/v1/customer/providers/nearby',
    nearby([
      card(rahimId, 'Rahim Uddin'),
      card(karimId, 'Karim Mia', badge: 'verified_pro', rating: 4.6),
    ]),
  );
  _reply(h, '/v1/customer/providers/$rahimId', publicProfile());
  _reply(h, '/v1/customer/providers/$rahimId/reviews', {
    'items': [review()],
  });
  _reply(h, '/v1/customer/bookings', {
    'items': [
      bookings.summary(),
      bookings.summary(id: 'b2', status: 'completed', service: 'Switch repair'),
    ],
  });
  _reply(h, '/v1/customer/bookings/${bookings.bookingId}', bookings.booking());
  _reply(h, '/v1/customer/notifications', {
    'items': [
      {
        'id': 'n1',
        'type': 'booking_accepted',
        'title': 'Rahim accepted your booking',
        'body': 'He will arrive at 10:30 am.',
        'bookingId': bookings.bookingId,
        'read': false,
        'createdAt': '2026-10-09T03:00:00Z',
      },
    ],
    'unreadCount': 1,
  });
  _reply(h, '/v1/customer/subscriptions', {'items': <Object>[]});
  return h;
}

Future<void> _look(
  WidgetTester tester,
  Harness h,
  ThemeMode mode,
  String l,
) async {
  await h.services.themeMode.select(mode);
  h.services.locale.select(Locale(l));
}

void main() {
  setUpAll(loadTourFonts);

  for (final (mode, lang) in tourVariants) {
    final look = '${mode.name}_$lang';
    testWidgets('signed-in screens, $look', (tester) async {
      phone(tester);
      final h = await _signedIn(tester);
      await _look(tester, h, mode, lang);
      await h.pumpApp(tester);
      for (final MapEntry(key: name, value: location) in _screens.entries) {
        await h.go(tester, location);
        await capture(tester, 'customer', '${name}_$look');
      }
    });

    testWidgets('signed-out screens, $look', (tester) async {
      phone(tester);
      final h = await Harness.create();
      await _look(tester, h, mode, lang);
      await h.pumpApp(tester, Routes.onboarding);
      await capture(tester, 'customer', 'onboarding_$look');
      await h.go(tester, Routes.phone);
      await capture(tester, 'customer', 'sign_in_$look');
    });
  }
}
