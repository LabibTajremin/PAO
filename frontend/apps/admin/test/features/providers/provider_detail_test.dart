import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_admin/features/providers/presentation/providers_page.dart';
import 'package:pao_l10n/pao_l10n.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _detail = '/v1/admin/providers/$providerId';
const _status = '/v1/admin/providers/$providerId/status';
final String _path = Routes.detail(Routes.providers, providerId);

void main() {
  testWidgets('a provider shows profile, verification, bookings and history', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_detail, (s) => s.reply(200, providerDetail()));
    await h.pumpApp(tester, _path);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    for (final text in [
      'Active',
      'Verified',
      'Flagged for review',
      'Online',
      '4.8',
      '132',
      'Male',
      '6 years',
      '+8801712345678',
      'Electrician',
      'National ID',
      'Expires 1 Mar 2027',
      'Skill proof · optional',
      'Photo is blurred',
      'PAO-104233 · Fan repair',
      'Suspended',
      'account.status_changed',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.textContaining('by support_agent'), findsWidgets);
    expect(find.text('Suspend'), findsOneWidget);
    expect(find.text('Ban'), findsOneWidget);
    await tester.tap(find.text('PAO-104233 · Fan repair'));
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  testWidgets('suspending asks for a reason and shows the new status', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(_detail, (s) => s.reply(200, providerDetail(full: false)))
      ..onPost(
        _status,
        (s) => s.reply(200, providerDetail(status: 'suspended', full: false)),
      );
    await h.pumpApp(tester, _path);
    expect(find.text('Nothing submitted yet.'), findsOneWidget);
    expect(find.text('No bookings yet.'), findsOneWidget);
    expect(find.text('No status changes yet.'), findsOneWidget);
    await tester.tap(find.text('Suspend'));
    await h.settle(tester);
    expect(find.text('Suspend Rahim Uddin?'), findsOneWidget);
    await tester.tap(find.text('Repeated no-shows'));
    await tester.tap(inDialog('Suspend'));
    await h.settle(tester);
    expect(h.bodyOf(_status), {
      'status': 'suspended',
      'reason': 'Repeated no-shows',
    });
    expect(find.text('Account status updated.'), findsOneWidget);
    expect(find.text('Reinstate'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
  });

  testWidgets('a ban explains what it blocks; a refusal is shown', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(_detail, (s) => s.reply(200, providerDetail(status: 'banned')))
      ..onPost(_status, (s) => s.reply(409, apiError('CONFLICT')));
    await h.pumpApp(tester, _path);
    expect(find.text('Ban'), findsNothing);
    await tester.tap(find.text('Reinstate'));
    await h.settle(tester);
    await tester.tap(find.text('Appeal accepted'));
    await tester.tap(inDialog('Reinstate'));
    await h.settle(tester);
    expect(h.bodyOf(_status), containsPair('status', 'active'));
    expect(
      find.text(failureMessage(lookupPaoL10n(const Locale('en')), 'CONFLICT')),
      findsOneWidget,
    );
  });

  testWidgets('banning a suspended provider names the NID, phone and face', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(
      _detail,
      (s) => s.reply(200, providerDetail(status: 'suspended')),
    );
    await h.pumpApp(tester, _path);
    await tester.tap(find.text('Ban'));
    await h.settle(tester);
    expect(
      find.text(
        'Ban Rahim Uddin? Their NID, phone and face cannot register again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == _status), isEmpty);
  });

  testWidgets('a verifier sees the provider without actions or links', (
    tester,
  ) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(
      tester,
      screens: ['A05', 'A06', 'A07', 'A08'],
      permissions: ['verification:review', 'provider:read'],
    );
    h.http.onGet(_detail, (s) => s.reply(200, providerDetail()));
    await h.pumpApp(tester, _path);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
    await tester.tap(find.text('PAO-104233 · Fan repair'));
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsNothing);
  });

  testWidgets('a failed load can be retried; the back link returns', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(_detail, (s) => s.reply(404, apiError('NOT_FOUND')))
      ..onGet(
        '/v1/admin/providers',
        (s) => s.reply(200, {'items': <Object?>[]}),
      );
    await h.pumpApp(tester, _path);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(_detail, (s) => s.reply(200, providerDetail()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    await tester.tap(find.text('All providers'));
    await h.settle(tester);
    expect(find.byType(ProvidersPage), findsOneWidget);
  });

  testWidgets('the provider reads in Bangla', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.services.locale.value = PaoLocales.bangla;
    h.http.onGet(_detail, (s) => s.reply(200, providerDetail()));
    await h.pumpApp(tester, _path);
    expect(find.text('সব সেবাদাতা'), findsOneWidget);
    expect(find.text('৪.৮'), findsWidgets);
    expect(find.text('নাম'), findsOneWidget);
  });
}
