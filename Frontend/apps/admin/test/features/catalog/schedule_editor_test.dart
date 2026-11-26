import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_api/pao_api.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _path = '/v1/admin/catalog/services/$serviceId';
const Map<String, Object> _schedule = {
  'patterns': ['once', 'weekdays'],
  'windows': [
    {'start': '12:00', 'end': '13:00'},
  ],
  'leadHours': 12,
  'cutoff': '20:00',
  'unit': 'meals',
  'minQuantity': 1,
  'maxQuantity': 50,
};

Future<Harness> _open(WidgetTester tester, Map<String, Object?> service) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester);
  h.http.onGet(
    catalogPath,
    (s) => s.reply(
      200,
      tree(
        categories: [
          category(services: [service]),
        ],
      ),
    ),
  );
  await h.pumpApp(tester, Routes.serviceOf(serviceId));
  return h;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pick<T>(WidgetTester tester, String option) async {
  await _tap(tester, find.byType(DropdownButtonFormField<T>));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, Harness h) async {
  await _tap(tester, find.text('Save'));
  await h.settle(tester);
}

void main() {
  testWidgets('a scheduled-delivery service needs valid ordering rules', (
    tester,
  ) async {
    final h = await _open(tester, service());
    expect(find.text('Delivery schedule'), findsNothing);
    await _pick<ServiceModel>(tester, 'Scheduled delivery');
    expect(find.text('Delivery schedule'), findsOneWidget);
    await tester.enterText(field('Cutoff the day before'), '8pm');
    await tester.enterText(field('Smallest order'), '9');
    await tester.enterText(field('Largest order'), '2');
    await _save(tester, h);
    expect(find.text('Choose at least one.'), findsOneWidget);
    expect(find.text('Use 24-hour times like 12:00-13:00.'), findsNWidgets(2));
    await _tap(tester, find.text('Once a month'));
    await _tap(tester, find.text('One time'));
    await _tap(tester, find.text('Chosen days'));
    await _tap(tester, find.text('Once a month'));
    await tester.enterText(
      field('Delivery windows'),
      '12:00-13:00, 19:00-21:00',
    );
    await tester.enterText(field('Cutoff the day before'), '18:00');
    await tester.enterText(field('Lead time (hours)'), '24');
    await tester.enterText(field('Smallest order'), '5');
    await tester.enterText(field('Largest order'), '300');
    await _pick<QuantityUnit>(tester, 'Guests');
    h.http.onPut(_path, (s) => s.reply(200, service()));
    await _save(tester, h);
    final body = h.bodyOf(_path)! as Map;
    expect(body['serviceModel'], 'scheduled_delivery');
    expect(body['schedule'], {
      'patterns': ['once', 'weekdays'],
      'windows': [
        {'start': '12:00', 'end': '13:00'},
        {'start': '19:00', 'end': '21:00'},
      ],
      'leadHours': 24,
      'cutoff': '18:00',
      'unit': 'guests',
      'minQuantity': 5,
      'maxQuantity': 300,
    });
  });

  testWidgets(
    'a saved schedule is sent back unchanged; windows must run forward',
    (tester) async {
      final h = await _open(tester, {
        ...service(),
        'serviceModel': 'scheduled_delivery',
        'schedule': _schedule,
      });
      expect(find.text('12:00-13:00'), findsOneWidget);
      await tester.enterText(field('Delivery windows'), '13:00-12:00');
      await _save(tester, h);
      expect(find.text('Use 24-hour times like 12:00-13:00.'), findsOneWidget);
      await tester.enterText(field('Delivery windows'), '12:00-13:00');
      h.http.onPut(_path, (s) => s.reply(200, service()));
      await _save(tester, h);
      expect((h.bodyOf(_path)! as Map)['schedule'], _schedule);
      await _pick<ServiceModel>(tester, 'On-demand visit');
      expect(find.text('Delivery schedule'), findsNothing);
      await _save(tester, h);
      expect((h.bodyOf(_path)! as Map).containsKey('schedule'), isFalse);
    },
  );
}
