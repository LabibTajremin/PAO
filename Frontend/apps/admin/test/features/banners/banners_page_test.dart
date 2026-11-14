import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/banners/presentation/banners_page.dart';

import '../../support/harness.dart';
import '../catalog/fixtures.dart';

const _path = '/v1/admin/catalog/banners';

Map<String, Object?> _banner(String id, {bool published = true}) => {
  'id': id,
  'title': named('Title $id'),
  'subtitle': ?(id == 'b1' ? named('Subtitle $id') : null),
  'sortOrder': id == 'b1' ? 0 : 1,
  'published': published,
};

Future<Harness> _open(WidgetTester tester, List<Object?> banners) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(catalogPath, (s) => s.reply(200, tree()))
    ..onGet(_path, (s) => s.reply(200, {'banners': banners}));
  await h.pumpApp(tester, Routes.catalog);
  await tester.tap(find.text('Home banners'));
  await h.settle(tester);
  return h;
}

Object? _sentBody(Harness h, String method) {
  final data = h.sent.lastWhere((o) => o.method == method).data;
  return data is String ? jsonDecode(data) : data;
}

Future<void> _type(WidgetTester tester, int field, String text) =>
    tester.enterText(find.byType(TextField).at(field), text);

void main() {
  testWidgets('admins add a banner, checked before it is sent', (tester) async {
    final h = await _open(tester, []);
    expect(find.byType(BannersPage), findsOneWidget);
    expect(find.text('No banners yet'), findsOneWidget);
    await tester.tap(find.text('New banner'));
    await h.settle(tester);
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'POST'), isEmpty);
    await _type(tester, 0, 'Eid offer');
    await _type(tester, 1, 'ঈদ অফার');
    await _type(tester, 4, 'http://plain.example.com/a.jpg');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Use an https link'), findsOneWidget);
    await _type(tester, 4, 'https://cdn.example.com/a.jpg');
    await tester.tap(find.text('None'));
    await h.settle(tester);
    await tester.tap(find.text('Electrician').last);
    await h.settle(tester);
    await tester.tap(find.byType(Switch));
    h.http.onPost(_path, (s) => s.reply(201, _banner('b9')));
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Saved.'), findsOneWidget);
    expect(_sentBody(h, 'POST'), {
      'title': {'en': 'Eid offer', 'bn': 'ঈদ অফার'},
      'imageUrl': 'https://cdn.example.com/a.jpg',
      'serviceId': serviceId,
      'sortOrder': 0,
      'published': true,
    });
  });

  testWidgets('admins edit and delete banners; refusals stay in the form', (
    tester,
  ) async {
    final h = await _open(tester, [
      _banner('b1'),
      _banner('b2', published: false),
    ]);
    expect(find.text('Subtitle b1'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    await tester.tap(find.text('Title b1'));
    await h.settle(tester);
    h.http.onPut(
      '$_path/b1',
      (s) => s.reply(422, apiError('VALIDATION_FAILED')),
    );
    await _type(tester, 5, '-2');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Edit banner'), findsOneWidget);
    expect((_sentBody(h, 'PUT')! as Map)['subtitle'], named('Subtitle b1'));
    await tester.tap(find.text('Delete banner').first);
    await h.settle(tester);
    await tester.tap(find.text('Cancel').last);
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'DELETE'), isEmpty);
    h.http.onDelete('$_path/b1', (s) => s.reply(204, null));
    await tester.tap(find.text('Delete banner').first);
    await h.settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete banner'));
    await h.settle(tester);
    expect(find.text('Banner deleted'), findsOneWidget);
  });
}
