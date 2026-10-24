import '../service/fixtures.dart';

/// Provider IDs.
const rahimId = 'f0000000-0000-4000-8000-000000000001';

/// A PAO Verified Pro provider with a lower rating.
const karimId = 'f0000000-0000-4000-8000-000000000002';

/// A PAO Verified Pro provider on the second page.
const salmaId = 'f0000000-0000-4000-8000-000000000003';

/// One provider card.
Map<String, Object?> card(
  String id,
  String name, {
  String badge = 'verified',
  double rating = 4.8,
  int distance = 1200,
}) => {
  'id': id,
  'name': name,
  'badge': badge,
  'level': badge == 'verified_pro' ? 2 : 1,
  'rating': rating,
  'ratingCount': 132,
  'completedJobs': 210,
  'distanceM': distance,
};

/// `GET /v1/customer/providers/nearby`.
Map<String, Object?> nearby(List<Map<String, Object?>> items, {String? next}) =>
    {
      'items': items,
      'priceSummary': {
        'subServiceId': fanId,
        'quantity': 2,
        'unitPrice': 50000,
        'total': 100000,
      },
      'nextCursor': ?next,
    };

/// `GET /v1/customer/providers/{id}`.
Map<String, Object?> publicProfile({String bio = 'Licensed electrician.'}) => {
  'id': rahimId,
  'name': 'Rahim Uddin',
  'badge': 'verified',
  'level': 1,
  'bio': bio,
  'experienceYears': 8,
  'services': [
    {'id': electricianId, 'name': named('Electrician')},
  ],
  'rating': {
    'average': bio.isEmpty ? 0 : 4.8,
    'count': bio.isEmpty ? 0 : 132,
    'distribution': {'1': 1, '3': 4, '4': 20, '5': 107},
  },
  'completedJobs': 210,
  'memberSince': '2025-03-01T00:00:00Z',
};

/// One review.
Map<String, Object?> review({String author = 'Nusrat', bool full = true}) => {
  'id': 'r0000000-0000-4000-8000-000000000001',
  'bookingId': 'b0000000-0000-4000-8000-000000000001',
  'stars': 5,
  'tags': full ? ['on_time', 'clean'] : <String>[],
  if (full) 'comment': 'Quick and tidy.',
  'authorName': author,
  if (full) 'serviceName': named('Electrician'),
  'createdAt': '2026-10-08T08:00:00Z',
};
