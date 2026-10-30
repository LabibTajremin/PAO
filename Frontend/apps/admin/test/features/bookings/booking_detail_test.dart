import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/bookings/presentation/bookings_page.dart';
import 'package:pao_admin/features/customers/presentation/customer_detail_page.dart';
import 'package:pao_admin/features/providers/presentation/provider_detail_page.dart';

import '../../support/harness.dart';
import '../providers/fixtures.dart';
import 'fixtures.dart';

const _detail = '/v1/admin/bookings/$bookingId';
final String _path = Routes.detail(Routes.bookings, bookingId);

void main() {
  testWidgets('a booking shows parties, items, extras and its timeline', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_detail, (s) => s.reply(200, booking()));
    await h.pumpApp(tester, _path);
    for (final text in [
      'PAO-104233',
      'Fan repair',
      '9 Oct 2026, 10:00 AM',
      '10 Oct 2026, 11:00 AM',
      '10 Oct 2026, 3:00 PM',
      '10 Oct 2026, 11:10 AM',
      '10 Oct 2026, 2:00 PM',
      'Cash received',
      'House 12, Road 5, Flat 3B, Banani',
      'Gate code 1234',
      'Ceiling fan',
      '2 × ৳500',
      'Extra',
      'Approved by the customer',
      'Capacitor',
      'Adds ৳130; new total ৳1,130',
      'Requested',
      'Accepted',
      'In progress',
      'Completed',
      'Provider · +8801712345678',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.textContaining('· System'), findsOneWidget);
    await tester.tap(find.text('Rahim Uddin'));
    await h.settle(tester);
    expect(find.byType(ProviderDetailPage), findsOneWidget);
  });

  testWidgets('a cancelled booking shows who cancelled and why', (
    tester,
  ) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_detail, (s) => s.reply(200, booking(cancelled: true)));
    await h.pumpApp(tester, _path);
    expect(find.text('As soon as possible'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Not assigned yet'), findsOneWidget);
    expect(find.text('Cancelled by Customer'), findsOneWidget);
    expect(find.text('changed_mind'), findsWidgets);
    expect(find.text('Proposed extras'), findsNothing);
    await tester.tap(find.text('Nusrat Jahan'));
    await h.settle(tester);
    expect(find.byType(CustomerDetailPage), findsOneWidget);
  });

  testWidgets('extras waiting or declined, an admin cancellation', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester, screens: ['A10']);
    h.http.onGet(_detail, (s) => s.reply(200, bookingWithExtras('pending')));
    await h.pumpApp(tester, _path);
    expect(find.text('Waiting for the customer'), findsOneWidget);
    expect(find.text('Cancelled by Admin'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    await tester.tap(find.text('Rahim Uddin'));
    await h.settle(tester);
    expect(find.byType(ProviderDetailPage), findsNothing);
    h.http.onGet(_detail, (s) => s.reply(200, bookingWithExtras('declined')));
    await h.go(tester, Routes.bookings);
    await h.go(tester, _path);
    expect(find.text('Declined by the customer'), findsOneWidget);
  });

  testWidgets('a failed booking can be retried; the back link returns', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(_detail, (s) => s.reply(500, apiError('INTERNAL')))
      ..onGet(
        '/v1/admin/bookings',
        (s) => s.reply(200, {'items': <Object?>[]}),
      );
    await h.pumpApp(tester, _path);
    h.http.onGet(_detail, (s) => s.reply(200, booking()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Gate code 1234'), findsOneWidget);
    await tester.tap(find.text('All bookings'));
    await h.settle(tester);
    expect(find.byType(BookingsPage), findsOneWidget);
  });
}
