import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';

import '../features/catalog/fixtures.dart' as catalog;
import '../features/complaints/fixtures.dart' as complaints;
import '../features/customers/fixtures.dart';
import '../features/providers/fixtures.dart';
import '../features/verification/fixtures.dart' as verification;
import '../support/harness.dart';
import 'tour_support.dart';

/// Every screen of the tour and its location.
const Map<String, String> _screens = {
  'dashboard': Routes.dashboard,
  'catalog': Routes.catalog,
  'verification': Routes.verification,
  'providers': Routes.providers,
  'customers': Routes.customers,
  'bookings': Routes.bookings,
  'complaints': Routes.complaints,
  'orders': Routes.orders,
};

void _reply(Harness h, String path, Object? body) =>
    h.http.onGet(path, (s) => s.reply(200, withBangla(body)));

Future<Harness> _signedIn(WidgetTester tester) async {
  final h = Harness.create();
  await h.signIn(tester);
  _reply(h, '/v1/me', complaints.me());
  _reply(h, '/v1/admin/dashboard', {
    'providersByStatus': {'pending': 34, 'active': 120, 'suspended': 2},
    'providersByLevel': {'0': 34, '1': 100, '2': 20},
    'bookingsPerDay': [
      for (var d = 3; d <= 9; d++)
        {'date': '2026-10-0$d', 'total': 6 + d, 'completed': 4 + d},
    ],
    'completionRate': 0.86,
    'openComplaints': 5,
    'pendingVerifications': 34,
    'generatedAt': '2026-10-09T04:00:00Z',
  });
  _reply(h, catalog.catalogPath, catalog.tree());
  _reply(
    h,
    '/v1/admin/verifications',
    verification.queue([verification.queueRow()]),
  );
  _reply(h, '/v1/admin/providers', {
    'items': [providerSummary()],
  });
  _reply(h, '/v1/admin/customers', {
    'items': [customerSummary()],
  });
  _reply(h, '/v1/admin/bookings', {
    'items': [bookingSummary()],
  });
  _reply(h, '/v1/admin/complaints', {
    'items': [complaints.complaint()],
  });
  _reply(h, '/v1/admin/subscriptions', {'items': <Object>[]});
  return h;
}

void main() {
  setUpAll(loadTourFonts);

  for (final (mode, lang) in tourVariants) {
    final look = '${mode.name}_$lang';
    testWidgets('admin screens, $look', (tester) async {
      laptop(tester);
      final h = await _signedIn(tester);
      h.services.themeMode.value = mode;
      h.services.locale.select(Locale(lang));
      await h.pumpApp(tester);
      for (final MapEntry(key: name, value: location) in _screens.entries) {
        await h.go(tester, location);
        await capture(tester, 'admin', '${name}_$look');
      }
    });

    testWidgets('sign-in, $look', (tester) async {
      laptop(tester);
      final h = Harness.create();
      h.services.themeMode.value = mode;
      h.services.locale.select(Locale(lang));
      await h.pumpApp(tester, Routes.login);
      await capture(tester, 'admin', 'sign_in_$look');
    });
  }
}
