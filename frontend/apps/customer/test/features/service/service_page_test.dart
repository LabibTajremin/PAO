import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/providers/presentation/providers_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

Future<Harness> _start(WidgetTester tester) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      '/v1/customer/services/$electricianId',
      (s) => s.reply(200, service()),
    )
    ..onGet('/v1/customer/services/$salonId', (s) => s.reply(200, salon()))
    ..onGet('/v1/customer/services/$driverId', (s) => s.reply(200, driver()));
  return h;
}

Map<String, String> _providersQuery(WidgetTester tester) =>
    tester.widget<ProvidersPage>(find.byType(ProvidersPage)).query;

Future<void> _tapMore(WidgetTester tester, Harness h, [int index = 0]) async {
  await tester.tap(find.byTooltip('More').at(index));
  await h.settle(tester);
}

void main() {
  testWidgets('sub-services with prices, quantities and a total', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.pumpApp(tester, Routes.serviceOf(electricianId));
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
    expect(find.text('Spare parts'), findsOneWidget);
    expect(find.text('Ceiling or table fan'), findsOneWidget);
    expect(find.text('Choose at least one item to continue.'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await _tapMore(tester, h);
    }
    await _tapMore(tester, h, 1);
    expect(find.text('৳1,800'), findsOneWidget);
    await tester.tap(find.byTooltip('Less').at(1));
    await h.settle(tester);
    expect(find.text('৳1,500'), findsOneWidget);
    await tester.tap(find.text('See providers'));
    await h.settle(tester);
    expect(_providersQuery(tester), {
      'service': electricianId,
      'items': '$fanId:3',
    });
  });

  testWidgets('home salon notes women providers; search preselects', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.pumpApp(tester, '${Routes.serviceOf(salonId)}?sub=s1');
    expect(find.text('Only women providers do this service.'), findsOneWidget);
    expect(find.text('৳500'), findsWidgets);
    expect(find.text('৳500 per job'), findsOneWidget);
  });

  testWidgets('driver hire needs a duty and a future start', (tester) async {
    final h = await _start(tester);
    await h.pumpApp(tester, Routes.serviceOf(driverId));
    expect(find.text('1 hour'), findsOneWidget);
    await _tapMore(tester, h);
    expect(find.text('2 hours'), findsOneWidget);
    expect(find.text('Choose when the driver should start.'), findsOneWidget);
    await tester.tap(find.textContaining('Daily'));
    await h.settle(tester);
    expect(find.text('1 day'), findsOneWidget);
    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('Choose a start time in the future.'), findsOneWidget);
    await tester.tap(find.text('Fri, 9 Oct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9:00 AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See providers'));
    await h.settle(tester);
    expect(_providersQuery(tester), {
      'service': driverId,
      'items': '$dailyId:1',
      'at': '2026-10-10T03:00:00.000Z',
    });
  });

  testWidgets('failures retry; a service with nothing to book says so', (
    tester,
  ) async {
    final h = await _start(tester);
    h.http.onGet(
      '/v1/customer/services/$electricianId',
      (s) => s.reply(404, apiError('NOT_FOUND')),
    );
    await h.pumpApp(tester, Routes.serviceOf(electricianId));
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(
      '/v1/customer/services/$electricianId',
      (s) => s.reply(200, service(subs: [])),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(
      find.text('Nothing can be booked for this service yet.'),
      findsOneWidget,
    );
    expect(find.byType(PaoButton), findsNothing);
  });
}
