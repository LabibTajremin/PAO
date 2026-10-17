import '../providers/fixtures.dart';

/// A complaint's ID.
const complaintId = '66666666-6666-6666-6666-666666666666';

/// The signed-in admin's ID.
const meId = '77777777-7777-7777-7777-777777777777';

/// Another support agent's ID.
const otherId = '88888888-8888-8888-8888-888888888888';

/// `GET /v1/me` for the signed-in admin.
Map<String, Object?> me() => {
  'id': meId,
  'email': 'support@pao.bd',
  'roles': ['support_agent'],
  'status': 'active',
  'createdAt': '2026-01-01T00:00:00Z',
};

/// A complaint, as listed and as shown in full.
Map<String, Object?> complaint({
  String status = 'open',
  String? assignee,
  String reporterRole = 'customer',
  bool full = true,
}) => {
  'id': complaintId,
  'ticketNumber': 'TCK-002341',
  'bookingId': bookingId,
  'reporterRole': reporterRole,
  'reporterId': reporterRole == 'customer' ? customerId : providerId,
  if (full) 'againstId': reporterRole == 'customer' ? providerId : customerId,
  'reason': 'poor_quality',
  'description': 'The fan still wobbles after installation.',
  if (full) 'photoMediaIds': [otherId, meId],
  'status': status,
  'assigneeId': ?assignee,
  if (status == 'resolved') ...{
    'resolution': 'Provider revisited and fixed the fan.',
    'verified': full,
    if (full) 'resolvedAt': '2026-10-09T03:00:00Z',
  },
  if (full)
    'comments': [
      {
        'authorId': meId,
        'body': 'Called the customer.',
        'at': '2026-10-08T05:00:00Z',
      },
      {
        'authorId': otherId,
        'body': 'Provider says it was fine.',
        'at': '2026-10-08T06:00:00Z',
      },
    ],
  'createdAt': '2026-10-08T04:00:00Z',
};

/// One admin user from `GET /v1/admin/admin-users`.
Map<String, Object?> agent({
  String id = otherId,
  String name = 'Farhana Akter',
  List<String> roles = const ['support_agent'],
  bool active = true,
}) => {
  'id': id,
  'email': '${name.split(' ').first.toLowerCase()}@pao.bd',
  'name': name,
  'roles': roles,
  'active': active,
  'totpEnrolled': true,
};
