import '../jobs/fixtures.dart';

/// API replies shared by the profile tests.
const serviceId = '88888888-8888-8888-8888-888888888888';

/// Another published service in the catalog.
const otherServiceId = '99999999-9999-9999-9999-999999999999';

/// `GET /v1/provider/profile`.
Map<String, Object?> profile({
  String? bio = 'Licensed electrician.',
  int level = 1,
  String badge = 'verified',
  bool homeBase = true,
}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'name': 'Rahim Uddin',
  'phone': '+8801712345678',
  'bio': ?bio,
  'status': 'active',
  'level': level,
  'badge': badge,
  'online': false,
  'language': 'en',
  'services': [
    {'id': serviceId, 'name': named('Electrician')},
  ],
  'experienceYears': 8,
  'homeBase': ?(homeBase ? {'lat': 23.79, 'lng': 90.4} : null),
  'workingRadiusM': ?(homeBase ? 5000 : null),
};

/// `GET /v1/provider/rating`.
Map<String, Object?> rating({int count = 132}) => {
  'average': count == 0 ? 0 : 4.8,
  'count': count,
  'distribution': {'1': 1, '3': 4, '4': 20, '5': 107},
};

/// One review.
Map<String, Object?> review({
  String author = 'Nusrat',
  String? comment = 'Quick and tidy.',
  bool service = true,
}) => {
  'id': '12121212-1212-1212-1212-121212121212',
  'bookingId': bookingId,
  'stars': 5,
  'tags': ['on_time', 'clean'],
  'comment': ?comment,
  'authorName': author,
  'serviceName': ?(service ? named('Electrician') : null),
  'createdAt': '2026-10-08T08:00:00Z',
};

/// `GET /v1/provider/verification` with documents.
Map<String, Object?> verificationStatus({
  int level = 1,
  Map<String, Object?>? level2,
  List<Map<String, Object?>>? items,
}) => {
  'level': level,
  'badge': level == 2 ? 'verified_pro' : 'verified',
  'canReceiveBookings': true,
  'items':
      items ??
      [
        {'type': 'nid', 'status': 'approved', 'required': true},
        {
          'type': 'police_clearance',
          'status': 'approved',
          'required': true,
          'expiresAt': '2026-10-20T00:00:00Z',
        },
        {
          'type': 'selfie',
          'status': 'rejected',
          'required': true,
          'rejectionReason': 'Photo is blurred.',
        },
        {
          'type': 'skill_proof',
          'status': 'expired',
          'required': false,
          'expiresAt': '2026-09-01T00:00:00Z',
        },
        {
          'type': 'address',
          'status': 'pending',
          'required': true,
          'expiresAt': '2027-10-01T00:00:00Z',
        },
      ],
  'level2': ?level2,
};

/// `GET /v1/provider/catalog` with one unpublished service.
Map<String, Object?> catalog() {
  Map<String, Object?> service(
    String id,
    String name, {
    bool published = true,
  }) => {
    'id': id,
    'categoryId': '13131313-1313-1313-1313-131313131313',
    'name': named(name),
    'iconKey': 'bolt',
    'serviceModel': 'on_demand',
    'requiredLevel': 1,
    'searchRadiusM': 5000,
    'womenProvidersOnly': false,
    'requiresLevel2': false,
    'published': published,
  };
  return {
    'version': 7,
    'categories': [
      {
        'id': '13131313-1313-1313-1313-131313131313',
        'name': named('Home'),
        'iconKey': 'home',
        'sortOrder': 1,
        'published': true,
        'services': [
          service(serviceId, 'Electrician'),
          service(otherServiceId, 'Plumber'),
          service(
            '14141414-1414-1414-1414-141414141414',
            'Hidden',
            published: false,
          ),
        ],
      },
    ],
  };
}

/// `PUT /v1/provider/enrolment/*` reply.
Map<String, Object?> enrolment() => {
  'steps': <Object?>[],
  'complete': true,
  'submitted': true,
};
