import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/catalog/presentation/service_editor_page.dart';
import 'package:pao_l10n/pao_l10n.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _categories = '/v1/admin/catalog/categories';

Future<Harness> _open(WidgetTester tester, [Object? reply]) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester);
  h.http.onGet(catalogPath, (s) => s.reply(200, reply ?? tree()));
  await h.pumpApp(tester, Routes.catalog);
  return h;
}

Future<void> _save(WidgetTester tester, Harness h) async {
  await tester.tap(find.text('Save'));
  await h.settle(tester);
}

void main() {
  testWidgets('the tree lists categories, services and sub-services', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(find.text('Version 7'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Cleaning')).dy,
      lessThan(tester.getTopLeft(find.text('Electrical')).dy),
    );
    expect(find.text('বাংলা Electrical · order 2 · 1 services'), findsOne);
    expect(find.text('On-demand visit · Level 1 · Verified'), findsOne);
    expect(find.text('Ceiling fan installation'), findsOneWidget);
    expect(find.text('৳500 per unit'), findsNWidgets(2));
    expect(find.text('Hidden'), findsNWidgets(2));
    await tester.tap(find.text('Electrician'));
    await h.settle(tester);
    expect(find.byType(ServiceEditorPage), findsOneWidget);
    await h.go(tester, Routes.catalog);
    await tester.tap(find.text('New service').first);
    await h.settle(tester);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('Service details'), findsOneWidget);
  });

  testWidgets('a new category is checked, refused, then saved', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('New category'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Sort order'), 'x');
    await _save(tester, h);
    expect(find.text('Fill this in.'), findsNWidgets(3));
    expect(find.text('Enter a whole number.'), findsOneWidget);
    await tester.enterText(field('Name (English)'), ' Plumbing ');
    await tester.enterText(field('Name (Bangla)'), 'প্লাম্বিং');
    await tester.enterText(field('Sort order'), '3');
    await tester.tap(find.byTooltip('Pick a known icon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('faucet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    h.http.onPost(_categories, (s) => s.reply(409, apiError('CONFLICT')));
    await _save(tester, h);
    expect(find.text(failureMessage(_l10n(tester), 'CONFLICT')), findsOne);
    h.http.onPost(_categories, (s) => s.reply(201, category()));
    await _save(tester, h);
    expect(find.text('Saved.'), findsOneWidget);
    expect(h.bodyOf(_categories), {
      'name': {'en': 'Plumbing', 'bn': 'প্লাম্বিং'},
      'iconKey': 'faucet',
      'sortOrder': 3,
      'published': true,
    });
  });

  testWidgets('a category is edited or left alone', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.byTooltip('Edit category').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsNothing);
    await tester.tap(find.byTooltip('Edit category').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);
    await tester.enterText(field('Icon key'), 'unknown-key');
    await tester.pump();
    expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    const path = '$_categories/$categoryId';
    h.http.onPut(path, (s) => s.reply(200, category()));
    await _save(tester, h);
    expect(h.bodyOf(path), {
      'name': named('Electrical'),
      'iconKey': 'unknown-key',
      'sortOrder': 2,
      'published': true,
    });
  });

  testWidgets('an empty catalog, and a failed one retried', (tester) async {
    final h = await _open(tester, tree(categories: []));
    expect(find.text('No categories yet'), findsOneWidget);
    h.http.onGet(catalogPath, (s) => s.reply(500, apiError('INTERNAL')));
    await h.go(tester, Routes.dashboard);
    await h.go(tester, Routes.catalog);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(catalogPath, (s) => s.reply(200, tree()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Electrical'), findsOneWidget);
  });

  testWidgets('the tree reads in Bangla', (tester) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.services.locale.select(PaoLocales.bangla);
    h.http.onGet(catalogPath, (s) => s.reply(200, tree()));
    await h.pumpApp(tester, Routes.catalog);
    expect(find.text('বাংলা Electrical'), findsOneWidget);
    expect(find.text('Electrical · ক্রম ২ · ১টি সেবা'), findsOneWidget);
  });

  testWidgets('on a phone-sized window the two languages stack', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(600, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(catalogPath, (s) => s.reply(200, tree()));
    await h.pumpApp(tester, Routes.catalog);
    await tester.tap(find.text('New category'));
    await tester.pumpAndSettle();
    final en = tester.getTopLeft(field('Name (English)'));
    final bn = tester.getTopLeft(field('Name (Bangla)'));
    expect(bn.dy, greaterThan(en.dy));
  });
}

PaoL10n _l10n(WidgetTester tester) =>
    PaoL10n.of(tester.element(find.byType(Scaffold).first));
