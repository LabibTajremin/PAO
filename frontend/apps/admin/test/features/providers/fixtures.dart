import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

/// Opens the filter menu labelled [menu] and picks [option].
Future<void> choose(
  WidgetTester tester,
  Harness h,
  String menu,
  String option,
) async {
  await tester.tap(find.text(menu));
  await h.settle(tester);
  await tester.tap(find.widgetWithText(CheckedPopupMenuItem<int>, option));
  await h.settle(tester);
}

/// The widget showing [text] inside the open dialog.
Finder inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

// API replies shared by the people, bookings and complaints tests.

/// A provider's ID.
const providerId = '11111111-1111-1111-1111-111111111111';

/// A customer's ID.
const customerId = '22222222-2222-2222-2222-222222222222';

/// A booking's ID.
const bookingId = '33333333-3333-3333-3333-333333333333';

/// A text in both languages.
Map<String, Object?> named(String en, [String bn = 'নাম']) => {
  'en': en,
  'bn': bn,
};

/// One row of `GET /v1/admin/providers`.
Map<String, Object?> providerSummary({
  String id = providerId,
  String name = 'Rahim Uddin',
  String status = 'active',
  bool flagged = false,
  String? phone = '+8801712345678',
}) => {
  'id': id,
  'name': name,
  'phone': ?phone,
  'status': status,
  'level': 1,
  'services': [
    {
      'id': '44444444-4444-4444-4444-444444444444',
      'name': named('Electrician'),
    },
  ],
  'rating': 4.8,
  'completedJobs': 132,
  'flaggedForReview': flagged,
  'online': true,
  'createdAt': '2026-01-05T04:00:00Z',
};

/// One recent booking on a person's record.
Map<String, Object?> bookingSummary({
  String id = bookingId,
  String status = 'completed',
  String? counterpart = 'Nusrat Jahan',
}) => {
  'id': id,
  'number': 'PAO-104233',
  'status': status,
  'serviceName': named('Fan repair'),
  'counterpartName': ?counterpart,
  'total': 113000,
  'createdAt': '2026-10-08T04:00:00Z',
};

/// One status change in the audit log.
Map<String, Object?> auditEntry({String? status = 'suspended'}) => {
  'id': '55555555-5555-5555-5555-555555555555',
  'at': '2026-10-01T04:00:00Z',
  'actorRole': 'support_agent',
  'action': 'account.status_changed',
  'subjectType': 'provider',
  'subjectId': providerId,
  'reason': 'Repeated no-shows',
  'after': ?(status == null ? null : {'status': status}),
};

/// `GET /v1/admin/providers/{id}`.
Map<String, Object?> providerDetail({
  String status = 'active',
  bool full = true,
}) => {
  'summary': providerSummary(status: status, flagged: full),
  if (full) ...{
    'gender': 'male',
    'experienceYears': 6,
    'complaints': 2,
    'cancellations30d': 1,
  },
  'items': full
      ? [
          {'type': 'nid', 'status': 'approved', 'required': true},
          {
            'type': 'police_clearance',
            'status': 'approved',
            'required': true,
            'expiresAt': '2027-03-01T00:00:00Z',
          },
          {
            'type': 'skill_proof',
            'status': 'rejected',
            'required': false,
            'rejectionReason': 'Photo is blurred',
          },
        ]
      : <Object?>[],
  'recentBookings': full ? [bookingSummary()] : <Object?>[],
  'statusHistory': full
      ? [auditEntry(), auditEntry(status: null)]
      : <Object?>[],
};
