import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

/// Settings endpoints.
const settingsPath = '/v1/admin/settings';

/// Admin users endpoint.
const adminsPath = '/v1/admin/admin-users';

/// Roles endpoint.
const rolesPath = '/v1/admin/roles';

/// Audit log endpoint.
const auditPath = '/v1/admin/audit';

/// An admin user's ID.
const rinaId = 'b0000000-0000-4000-8000-000000000001';

/// Another admin user's ID.
const karimId = 'b0000000-0000-4000-8000-000000000002';

/// Signs in with every permission and opens [location].
Future<Harness> openSettings(
  WidgetTester tester,
  String location, {
  List<String>? permissions,
}) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester, permissions: permissions);
  await h.pumpApp(tester, location);
  return h;
}

/// [target] inside the open dialog.
Finder inDialog(Finder target) =>
    find.descendant(of: find.byType(AlertDialog), matching: target);

/// The JSON body of the last [method] request.
Object? lastBody(Harness h, String method) {
  final data = h.sent.lastWhere((o) => o.method == method).data;
  return data is String ? jsonDecode(data) : data;
}

/// One setting.
Map<String, Object?> setting(
  String key,
  String type,
  String value, {
  bool updated = true,
}) => {
  'key': key,
  'value': value,
  'type': type,
  'description': 'About $key',
  if (updated) 'updatedAt': '2026-10-01T04:00:00Z',
};

/// `GET /v1/admin/settings`.
Map<String, Object?> settingList() => {
  'items': [
    setting('booking.accept_timeout_asap_seconds', 'integer', '180'),
    setting('rating.low_threshold', 'number', '3.5', updated: false),
    setting('booking.cash_only', 'boolean', 'true'),
    setting('support.phone', 'string', '+8809600000000'),
    setting('service.area', 'geojson', '{"type":"Polygon"}'),
  ],
};

/// One admin user.
Map<String, Object?> adminUser({
  String id = rinaId,
  String name = 'Rina Akter',
  List<String> roles = const ['verifier'],
  bool active = true,
  bool totp = true,
  bool signedIn = true,
}) => {
  'id': id,
  'email': '${name.split(' ').first.toLowerCase()}@pao.bd',
  'name': name,
  'roles': roles,
  'active': active,
  'totpEnrolled': totp,
  if (signedIn) 'lastLoginAt': '2026-10-08T04:00:00Z',
};

/// `GET /v1/admin/roles`.
Map<String, Object?> roleList() => {
  'items': [
    {
      'role': 'verifier',
      'permissions': ['verification:review', 'provider:read'],
      'screens': ['A02', 'A05'],
    },
    {
      'role': 'catalog_manager',
      'permissions': ['catalog:manage'],
      'screens': ['A02', 'A03'],
    },
  ],
  'allPermissions': [
    'verification:review',
    'provider:read',
    'catalog:manage',
    'level2:manage',
  ],
  'allScreens': ['A02', 'A03', 'A05', 'A07'],
};

/// One audit entry.
Map<String, Object?> auditEntry(
  String id, {
  String action = 'catalog.price_changed',
  bool actor = true,
  bool role = true,
}) => {
  'id': id,
  'at': '2026-10-08T06:30:00Z',
  if (actor) 'actorId': rinaId,
  if (actor && role) 'actorRole': 'catalog_manager',
  'action': action,
  'subjectType': 'sub_service',
  'subjectId': 'a0000000',
  if (actor) 'reason': 'Market rate',
  if (actor) 'before': {'amount': 45000},
  if (actor) 'after': {'amount': 50000},
};
