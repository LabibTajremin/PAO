import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_page.dart';
import 'package:pao_api/pao_api.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _services = '/v1/admin/catalog/services';
const _newId = '50000000-0000-4000-8000-000000000009';

Future<Harness> _open(WidgetTester tester, String location) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester);
  h.http.onGet(catalogPath, (s) => s.reply(200, tree()));
  await h.pumpApp(tester, location);
  return h;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

Future<void> _pick<T>(WidgetTester tester, String option) async {
  await _tap(tester, find.byType(DropdownButtonFormField<T>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, Harness h) async {
  await _tap(tester, find.text('Save'));
  await h.settle(tester);
}

void main() {
  testWidgets('a service is checked, refused, then saved', (tester) async {
    final h = await _open(tester, Routes.serviceOf(serviceId));
    expect(find.text('Electrician'), findsNWidgets(2));
    await tester.enterText(field('Search radius (metres)'), '100');
    await tester.enterText(field('Name (English)'), '');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await _save(tester, h);
    expect(find.text('Enter a number from 500 to 50000.'), findsOneWidget);
    expect(find.text('Fill this in.'), findsNWidgets(3));
    await tester.tap(find.byTooltip('Remove').last);
    await tester.pump();
    await tester.enterText(field('Name (English)'), 'Electrician pro');
    await tester.enterText(field('Search radius (metres)'), '8000');
    await _pick<String>(tester, 'Cleaning');
    await _pick<ServiceModel>(tester, 'Duration hire');
    await _pick<int>(tester, 'Level 2 · PAO Verified Pro');
    await tester.tap(find.text('Women providers only'));
    const path = '$_services/$serviceId';
    h.http.onPut(path, (s) => s.reply(422, apiError('VALIDATION_FAILED')));
    await _save(tester, h);
    expect(find.text('Please check the highlighted fields.'), findsOne);
    h.http.onPut(path, (s) => s.reply(200, service()));
    await _save(tester, h);
    expect(find.text('Saved.'), findsOneWidget);
    expect(h.bodyOf(path), {
      'categoryId': otherCategoryId,
      'name': {'en': 'Electrician pro', 'bn': 'বাংলা Electrician'},
      'iconKey': 'bolt',
      'serviceModel': 'duration_hire',
      'requiredLevel': 2,
      'searchRadiusM': 8000,
      'womenProvidersOnly': true,
      'requiresLevel2': true,
      'level2Checklist': [named('Safe isolation')],
      'published': true,
    });
  });

  testWidgets('a new service is created in its category, then opens', (
    tester,
  ) async {
    final h = await _open(
      tester,
      '${Routes.serviceOf('new')}?category=$categoryId',
    );
    expect(find.text('New service'), findsOneWidget);
    expect(find.text('Sub-services'), findsNothing);
    await tester.enterText(field('Name (English)'), 'AC repair');
    await tester.enterText(field('Name (Bangla)'), 'এসি মেরামত');
    await tester.enterText(field('Icon key'), 'ac');
    await tester.tap(find.text('Requires Level 2'));
    await tester.pump();
    await tester.tap(find.text('Requires Level 2'));
    await tester.tap(find.text('Published'));
    h.http
      ..onPost(_services, (s) => s.reply(201, service(id: _newId)))
      ..onGet(
        catalogPath,
        (s) => s.reply(
          200,
          tree(
            categories: [
              category(
                services: [service(id: _newId, name: 'AC repair')],
              ),
            ],
          ),
        ),
      );
    await _save(tester, h);
    expect(h.bodyOf(_services), {
      'categoryId': categoryId,
      'name': {'en': 'AC repair', 'bn': 'এসি মেরামত'},
      'iconKey': 'ac',
      'serviceModel': 'on_demand',
      'requiredLevel': 1,
      'searchRadiusM': 5000,
      'womenProvidersOnly': false,
      'requiresLevel2': false,
      'level2Checklist': <Object>[],
      'published': true,
    });
    await h.settle(tester);
    expect(find.text('AC repair'), findsWidgets);
    await reveal(tester, find.text('Sub-services'));
    expect(find.text('Sub-services'), findsOneWidget);
  });

  testWidgets('a new service needs a category', (tester) async {
    final h = await _open(tester, '${Routes.serviceOf('new')}?category=x');
    await _save(tester, h);
    expect(find.text('Fill this in.'), findsNWidgets(4));
    expect(h.sent.where((o) => o.method == 'POST'), isEmpty);
  });

  testWidgets('an unknown service is not found; back returns to the tree', (
    tester,
  ) async {
    final h = await _open(tester, Routes.serviceOf('missing'));
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to catalog'));
    await h.settle(tester);
    expect(find.byType(CatalogPage), findsOneWidget);
  });
}
