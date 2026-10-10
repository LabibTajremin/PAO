import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/setup_page.dart';
import 'package:pao_customer/features/booking/presentation/waiting_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'booking_fixtures.dart';

const _book = '/book?service=s1&items=x1:2,x3:1&provider=p1';

Future<Harness> _open(
  WidgetTester tester, {
  String location = _book,
  String model = 'on_demand',
  List<Map<String, Object?>>? addresses,
  bool failService = false,
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      '/v1/customer/services/s1',
      (s) => failService
          ? s.reply(500, apiError('INTERNAL'))
          : s.reply(200, service(model: model)),
    )
    ..onGet('/v1/customer/providers/p1', (s) => s.reply(200, providerProfile))
    ..onGet(
      '/v1/customer/addresses',
      (s) => s.reply(200, {
        'items':
            addresses ??
            [address('a2', label: 'office'), address('a1', isDefault: true)],
      }),
    );
  await h.pumpApp(tester, location);
  return h;
}

Future<void> _back(WidgetTester tester) async {
  GoRouter.of(tester.element(find.text('C25'))).pop();
  await tester.pumpAndSettle();
}

String? _key(Harness h) =>
    h.sent
            .lastWhere((o) => o.path == '/v1/customer/bookings')
            .headers['Idempotency-Key']
        as String?;

void main() {
  testWidgets('without a provider there is nothing to book', (tester) async {
    final h = await _open(tester, location: '${Routes.book}?service=s1');
    expect(find.byType(NothingToBook), findsOneWidget);
    await tester.tap(find.text('Browse services'));
    await h.settle(tester);
    expect(find.text('C37'), findsOneWidget);
  });

  testWidgets('shows the order and confirms an ASAP booking idempotently', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Verified Pro'), findsOneWidget);
    expect(find.text('★ 4.8 (132)'), findsOneWidget);
    expect(find.text('Item x1 × 2'), findsOneWidget);
    expect(find.text('Item x3 × 1'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('House a1, Road 5, Banani'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Gate 4');
    h.http.onPost(
      '/v1/customer/bookings',
      (s) => s.reply(409, apiError('PROVIDER_UNAVAILABLE')),
    );
    await tester.tap(find.text('Confirm booking · ৳1,000'));
    await h.settle(tester);
    expect(find.textContaining('not available'), findsOneWidget);
    final first = _key(h);
    h.http
      ..onPost('/v1/customer/bookings', (s) => s.reply(201, booking()))
      ..onGet(
        bookingPath,
        (s) => s.reply(
          200,
          booking(status: 'requested', deadline: '2026-10-09T04:02:00Z'),
        ),
      );
    await tester.tap(find.text('Confirm booking · ৳1,000'));
    await h.settle(tester);
    expect(_key(h), first);
    expect(h.bodyOf('/v1/customer/bookings'), {
      'providerId': 'p1',
      'serviceId': 's1',
      'items': [
        {'subServiceId': 'x1', 'quantity': 2},
      ],
      'timing': 'asap',
      'addressId': 'a1',
      'note': 'Gate 4',
    });
    expect(find.byType(WaitingPage), findsOneWidget);
  });

  testWidgets('the address sheet changes and adds addresses', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('Change'));
    await h.settle(tester);
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.text('Office'));
    await h.settle(tester);
    expect(find.text('House a2, Road 5, Banani'), findsOneWidget);
    await tester.tap(find.text('Change'));
    await h.settle(tester);
    await tester.tap(find.text('Add address'));
    await h.settle(tester);
    expect(find.text('C25'), findsOneWidget);
    await _back(tester);
    await h.settle(tester);
    expect(find.text('Office'), findsOneWidget);
    expect(
      h.sent.where((o) => o.path == '/v1/customer/addresses'),
      hasLength(2),
    );
  });

  testWidgets('without addresses the customer adds one first', (tester) async {
    final h = await _open(tester, addresses: [address('a5', label: 'other')]);
    expect(find.text('Other'), findsOneWidget);
    await h.go(tester, Routes.home);
    h.http.onGet(
      '/v1/customer/addresses',
      (s) => s.reply(200, {'items': <Object>[]}),
    );
    await h.go(tester, _book);
    expect(
      find.text('Add an address so the provider can find you.'),
      findsOneWidget,
    );
    final confirm = tester.widget<PaoButton>(
      find.widgetWithText(PaoButton, 'Confirm booking · ৳1,000'),
    );
    expect(confirm.onPressed, isNull);
    h.http.onGet(
      '/v1/customer/addresses',
      (s) => s.reply(200, {
        'items': [address('a9')],
      }),
    );
    await tester.tap(find.text('Add address'));
    await h.settle(tester);
    await _back(tester);
    await h.settle(tester);
    expect(find.text('House a9, Road 5, Banani'), findsOneWidget);
  });

  testWidgets('a scheduled booking is picked in Dhaka time', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('Schedule'));
    await h.settle(tester);
    await tester.tap(find.text('Pick a date and time'));
    await h.settle(tester);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.text('Pick a date and time'), findsOneWidget);
    await tester.tap(find.text('Pick a date and time'));
    await h.settle(tester);
    await tester.tap(find.text('OK'));
    await h.settle(tester);
    await tester.tap(find.text('OK'));
    await h.settle(tester);
    expect(find.text('Fri 9 Oct 2026, 11:00 AM'), findsOneWidget);
    await tester.tap(find.text('Fri 9 Oct 2026, 11:00 AM'));
    await h.settle(tester);
    await tester.tap(find.text('OK'));
    await h.settle(tester);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.text('Fri 9 Oct 2026, 11:00 AM'), findsOneWidget);
    h.http.onPost('/v1/customer/bookings', (s) => s.reply(201, booking()));
    h.http.onGet(bookingPath, (s) => s.reply(200, booking()));
    await tester.tap(find.text('Confirm booking · ৳1,000'));
    await h.settle(tester);
    final body = h.bodyOf('/v1/customer/bookings')! as Map<String, Object?>;
    expect(
      [body['timing'], body['scheduledAt']],
      ['scheduled', '2026-10-09T05:00:00.000Z'],
    );
  });

  testWidgets('a duration hire has no ASAP option and checks the time', (
    tester,
  ) async {
    final h = await _open(
      tester,
      location: '$_book&at=2026-10-09T04:10Z',
      model: 'duration_hire',
    );
    expect(find.text('As soon as possible'), findsNothing);
    await tester.tap(find.text('Confirm booking · ৳1,000'));
    await h.settle(tester);
    expect(find.textContaining('at least 1 hour'), findsOneWidget);
  });

  testWidgets('unbookable items show nothing to book', (tester) async {
    await _open(tester, location: '/book?service=s1&items=x3:1&provider=p1');
    expect(find.byType(NothingToBook), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    final h = await _open(tester, failService: true);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet('/v1/customer/services/s1', (s) => s.reply(200, service()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Item x1 × 2'), findsOneWidget);
  });

  testWidgets('the form reads in Bangla', (tester) async {
    final h = await _open(tester);
    h.services.locale.select(const Locale('bn'));
    await h.settle(tester);
    expect(find.text('যত দ্রুত সম্ভব'), findsOneWidget);
    expect(find.text('আইটেম x1 × ২'), findsOneWidget);
  });
}
