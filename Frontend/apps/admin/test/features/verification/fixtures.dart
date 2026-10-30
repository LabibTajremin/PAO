import 'package:pao_admin/features/verification/domain/verification_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Provider under review.
const rahim = 'p-rahim';

/// The next provider in the queue.
const karim = 'p-karim';

/// A queue row.
Map<String, Object?> queueRow({
  String id = rahim,
  String name = 'Rahim Uddin',
  int age = 18,
  List<String> pending = const ['nid', 'selfie'],
}) => {
  'providerId': id,
  'name': name,
  'services': [
    {
      'id': 's1',
      'name': {'en': 'Electrician', 'bn': 'ইলেকট্রিশিয়ান'},
    },
  ],
  'pendingItems': pending,
  'submittedAt': '2026-10-08T10:00:00Z',
  'ageHours': age,
};

/// `GET /v1/admin/verifications`.
Map<String, Object?> queue(List<Map<String, Object?>> rows, [String? next]) => {
  'items': rows,
  'nextCursor': ?next,
};

/// One review item.
Map<String, Object?> item(
  String type, {
  String status = 'pending',
  bool required = true,
  List<(String, String)> docs = const [],
  Map<String, String> fields = const {},
  String? reason,
  String? expires,
  String? decided,
}) => {
  'type': type,
  'status': status,
  'required': required,
  'rejectionReason': ?reason,
  'expiresAt': ?expires,
  'decidedAt': ?decided,
  'documents': [
    for (final (id, kind) in docs) {'mediaId': id, 'kind': kind},
  ],
  'fields': fields,
};

/// `GET /v1/admin/verifications/{id}`: NID and selfie pending, the rest in
/// every other state.
Map<String, Object?> reviewJson({
  int level = 0,
  String id = rahim,
  String? face = 'manual_review',
  List<Map<String, Object?>>? items,
}) => {
  'providerId': id,
  'level': level,
  'profile': {
    'fullName': 'Rahim Uddin',
    'dateOfBirth': '1990-05-17',
    'gender': 'male',
    'phone': '+8801711000000',
    'presentAddress': 'House 4, Road 2, Mirpur',
    'permanentAddress': '',
    'nidNumber': '1990123456789',
  },
  'faceMatch': ?face,
  'items': items ?? defaultItems(),
};

/// Every item type in a mix of states.
List<Map<String, Object?>> defaultItems() => [
  item('nid', docs: [('m-front', 'nid_front'), ('m-back', 'nid_back')]),
  item('selfie', docs: [('m-selfie', 'selfie')]),
  item(
    'police_clearance',
    status: 'approved',
    docs: [('m-police', 'police_clearance')],
    fields: {'issueDate': '2026-03-01'},
    expires: '2027-03-01T00:00:00Z',
    decided: '2026-10-01T06:00:00Z',
  ),
  item(
    'address',
    status: 'rejected',
    fields: {'presentAddress': 'Mirpur', 'permanentAddress': ''},
    reason: 'Name mismatch',
  ),
  item('emergency_contact', status: 'expired', fields: {'relation': 'Uncle'}),
  item('skill_proof', status: 'missing', required: false),
  item('service_area', status: 'approved', fields: {'custom': 'x'}),
  item('code_of_conduct', status: 'approved', docs: [('m-x', 'other')]),
];

/// [reviewJson] with every item decided.
Map<String, Object?> reviewDone({int level = 1}) => reviewJson(
  level: level,
  items: [item('nid', status: 'approved')],
);

/// A hand-written [VerificationRepository] for cubit tests.
class FakeVerificationRepository implements VerificationRepository {
  /// What [reviewJson] and the decisions return.
  VerificationReview current = VerificationReview.fromJson(reviewJson());

  /// Thrown by the next call when set.
  Exception? error;

  /// What [next] returns.
  String? nextId = karim;

  /// Decisions made, e.g. `approve nid`.
  final List<String> calls = [];

  Future<T> _reply<T>(T value) async {
    final e = error;
    if (e != null) throw e;
    return value;
  }

  @override
  Future<Paged<VerificationQueueItem>> queue({
    ItemType? itemType,
    String? cursor,
  }) => _reply(Paged([VerificationQueueItem.fromJson(queueRow())]));

  @override
  Future<VerificationReview> review(String providerId) => _reply(current);

  @override
  Future<VerificationReview> approve(String providerId, ItemType type) {
    calls.add('approve ${type.value}');
    return _reply(current);
  }

  @override
  Future<VerificationReview> reject(
    String providerId,
    ItemType type,
    String reason,
  ) {
    calls.add('reject ${type.value} $reason');
    return _reply(current);
  }

  @override
  Future<String> documentUrl(String mediaId) => _reply('https://x/$mediaId');

  @override
  Future<String?> next(String current) => _reply(nextId);
}
