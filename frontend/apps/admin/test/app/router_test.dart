import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/auth/presentation/login_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../support/harness.dart';

void main() {
  testWidgets('signed-out admins land on login', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.pumpApp(tester);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('a super admin reaches every console screen from the menu', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    expect(find.text('A02'), findsOneWidget);
    for (final (menu, screen) in [
      ('Verification', 'A05'),
      ('Level 2 sessions', 'A07'),
      ('Catalog', 'A03'),
      ('Providers', 'Search providers by name or phone'),
      ('Customers', 'Search customers by name or phone'),
      ('Bookings', 'Refreshes every 30 seconds'),
      ('Complaints', 'Assigned to me'),
      ('Settings', 'A12'),
    ]) {
      await tester.tap(find.text(menu));
      await h.settle(tester);
      expect(find.text(screen), findsOneWidget, reason: menu);
    }
    for (final (path, screen) in [
      (Routes.serviceOf('s1'), 'A04'),
      (Routes.reviewOf('p1'), 'A06'),
      (Routes.detail(Routes.providers, 'p1'), 'All providers'),
      (Routes.detail(Routes.customers, 'c1'), 'All customers'),
      (Routes.detail(Routes.bookings, 'b1'), 'All bookings'),
      (Routes.detail(Routes.complaints, 'k1'), 'All complaints'),
      (Routes.settingsTab('audit'), 'A12'),
      (Routes.settingsTab(''), 'A12'),
    ]) {
      await h.go(tester, path);
      expect(find.text(screen), findsOneWidget, reason: path);
    }
  });

  testWidgets('the menu shows only permitted screens; others are denied', (
    tester,
  ) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester, screens: ['A02', 'A05']);
    await h.pumpApp(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Catalog'), findsNothing);
    await h.go(tester, Routes.catalog);
    expect(find.byType(PaoAccessDeniedView), findsOneWidget);
  });

  testWidgets('an expired session asks to sign in again', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    await h.services.sessions.signOut(expired: true);
    await h.settle(tester);
    expect(find.byType(PaoSessionExpiredView), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await h.settle(tester);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('log out ends the session even if the call fails', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    h.http.onPost('/v1/auth/logout', (s) => s.reply(500, null));
    await tester.tap(find.text('Log out'));
    await h.settle(tester);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(h.sent.last.path, '/v1/auth/logout');
  });

  test('the password gate holds until the password is replaced', () {
    expect(
      passwordGate(mustChange: true, path: Routes.dashboard),
      Routes.password,
    );
    expect(passwordGate(mustChange: true, path: Routes.password), isNull);
    expect(
      passwordGate(mustChange: false, path: Routes.password),
      Routes.dashboard,
    );
    expect(passwordGate(mustChange: false, path: Routes.catalog), isNull);
  });
}
