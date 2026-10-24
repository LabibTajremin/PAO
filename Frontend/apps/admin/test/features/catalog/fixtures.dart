import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/catalog/presentation/service_editor_page.dart';
import 'package:pao_ui/pao_ui.dart';

/// The admin catalog endpoint.
const catalogPath = '/v1/admin/catalog';

/// The Electrical category.
const categoryId = 'c0000000-0000-4000-8000-000000000001';

/// The Cleaning category, unpublished and empty.
const otherCategoryId = 'c0000000-0000-4000-8000-000000000002';

/// The Electrician service.
const serviceId = '50000000-0000-4000-8000-000000000001';

/// The ceiling fan sub-service.
const subId = 'a0000000-0000-4000-8000-000000000001';

/// An admin's account ID.
const adminId = 'b0000000-0000-4000-8000-000000000001';

/// The text field labelled [label] inside a `PaoTextField`.
Finder field(String label) => find.descendant(
  of: find.widgetWithText(PaoTextField, label),
  matching: find.byType(TextField),
);

/// Scrolls the service editor until [target] is built and on screen.
Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .descendant(
          of: find.byType(ServiceEditorPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// A catalog text in both languages.
Map<String, Object?> named(String en, [String? bn]) => {
  'en': en,
  'bn': bn ?? 'বাংলা $en',
};

/// One sub-service.
Map<String, Object?> subService({
  String id = subId,
  String name = 'Ceiling fan installation',
  bool published = true,
  int? maxQuantity = 4,
}) => {
  'id': id,
  'serviceId': serviceId,
  'name': named(name),
  'description': named('Mount and wire one fan'),
  'inclusions': [named('Wiring check')],
  'exclusions': <Object>[],
  'unit': 'unit',
  'price': 50000,
  'priceVersionId': 'd0000000-0000-4000-8000-000000000001',
  'maxQuantity': ?maxQuantity,
  'published': published,
};

/// One service with its sub-services.
Map<String, Object?> service({
  String id = serviceId,
  String name = 'Electrician',
  List<Map<String, Object?>>? subs,
}) => {
  'id': id,
  'categoryId': categoryId,
  'name': named(name),
  'iconKey': 'bolt',
  'serviceModel': 'on_demand',
  'requiredLevel': 1,
  'searchRadiusM': 5000,
  'womenProvidersOnly': false,
  'requiresLevel2': true,
  'level2Checklist': [named('Safe isolation')],
  'published': true,
  'subServices':
      subs ??
      [
        subService(),
        subService(
          id: 'a0000000-0000-4000-8000-000000000002',
          name: 'Socket repair',
          published: false,
          maxQuantity: null,
        ),
      ],
};

/// One category.
Map<String, Object?> category({
  String id = categoryId,
  String name = 'Electrical',
  int sortOrder = 2,
  bool published = true,
  List<Map<String, Object?>>? services,
}) => {
  'id': id,
  'name': named(name),
  'iconKey': 'plug',
  'sortOrder': sortOrder,
  'published': published,
  'services': services ?? [service()],
};

/// `GET /v1/admin/catalog`.
Map<String, Object?> tree({List<Map<String, Object?>>? categories}) => {
  'version': 7,
  'categories':
      categories ??
      [
        category(),
        category(
          id: otherCategoryId,
          name: 'Cleaning',
          sortOrder: 0,
          published: false,
          services: [],
        ),
      ],
};

/// One price version.
Map<String, Object?> priceVersion(int amount, String from) => {
  'id': 'e0000000-0000-4000-8000-${'$amount'.padLeft(12, '0')}',
  'subServiceId': subId,
  'amount': amount,
  'effectiveFrom': from,
  'createdBy': adminId,
};
