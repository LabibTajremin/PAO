import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';

import '../../support/harness.dart';
import '../location/fixtures.dart';
import '../service/fixtures.dart';

Map<String, Object?> _banner(
  String id, {
  String? service,
  String? image,
  bool subtitle = true,
}) => {
  'id': id,
  'title': named('Title $id'),
  'subtitle': ?(subtitle ? named('Subtitle $id') : null),
  'imageUrl': ?image,
  'serviceId': ?service,
  'sortOrder': 0,
  'published': true,
};

Future<Harness> _start(
  WidgetTester tester,
  List<Map<String, Object?>> banners, {
  String name = 'Nusrat Jahan',
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet('/v1/customer/profile', (s) => s.reply(200, profile(name: name)))
    ..onGet(
      '/v1/customer/addresses',
      (s) => s.reply(200, addressList([address()])),
    )
    ..onGet('/v1/customer/catalog', (s) => s.reply(200, catalog()))
    ..onGet(
      '/v1/customer/bookings',
      (s) => s.reply(200, {'items': <Object?>[]}),
    )
    ..onGet('/v1/customer/service-area', (s) => s.reply(200, coverage()))
    ..onGet('/v1/customer/banners', (s) => s.reply(200, {'banners': banners}));
  await tester.runAsync(h.services.gate.load);
  await h.pumpApp(tester);
  return h;
}

void main() {
  testWidgets('home greets by first name and shows the banners', (
    tester,
  ) async {
    final h = await _start(tester, [
      _banner('b1', service: salonId),
      _banner('b2', image: 'https://cdn.example.com/x.jpg', subtitle: false),
    ]);
    expect(find.text('Hi, Nusrat'), findsOneWidget);
    expect(find.text('Title b1'), findsOneWidget);
    expect(find.text('Subtitle b1'), findsOneWidget);
    expect(find.text('Book now →'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await h.settle(tester);
    expect(find.text('Title b2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await h.settle(tester);
    await tester.tap(find.text('Title b1'));
    await h.settle(tester);
    expect(find.byType(ServicePage), findsOneWidget);
  });

  testWidgets('a single banner has no dots and a nameless customer is '
      'greeted plainly', (tester) async {
    await _start(tester, [_banner('b1')], name: ' ');
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
    await tester.tap(find.text('Title b1'));
    await tester.pump();
    expect(find.byType(ServicePage), findsNothing);
  });
}
