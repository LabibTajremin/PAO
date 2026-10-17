import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// A provider at Level 1.
const providerId = 'prov-0001-rahim';

/// The electrician service.
const serviceId = 'serv-0001-electric';

/// A session ID.
const sessionId = 'sess-0001';

/// A service reference.
Map<String, Object?> serviceRef({String id = serviceId}) => {
  'id': id,
  'name': {'en': 'Electrician', 'bn': 'ইলেকট্রিশিয়ান'},
};

/// One `AdminProviderSummary`.
Map<String, Object?> providerJson({
  String id = providerId,
  String name = 'Rahim Uddin',
  String? phone = '+8801711000000',
  List<Map<String, Object?>>? services,
}) => {
  'id': id,
  'name': name,
  'phone': ?phone,
  'status': 'active',
  'level': 1,
  'services': services ?? [serviceRef()],
  'rating': 4.5,
  'completedJobs': 12,
  'flaggedForReview': false,
  'createdAt': '2026-01-01T00:00:00Z',
};

/// `GET /v1/admin/providers/{id}`.
Map<String, Object?> providerDetail({String id = providerId}) => {
  'summary': providerJson(id: id),
  'items': <Object?>[],
  'recentBookings': <Object?>[],
  'statusHistory': <Object?>[],
};

/// One `Level2Session`.
Map<String, Object?> sessionJson({
  String id = sessionId,
  String provider = providerId,
  String service = serviceId,
  String status = 'scheduled',
  String? result,
  List<Map<String, Object?>>? checklist,
  String? notes,
}) => {
  'id': id,
  'providerId': provider,
  'serviceId': service,
  'scheduledAt': '2026-10-12T04:00:00Z',
  'location': 'PAO office, Gulshan 1',
  'status': status,
  'result': ?result,
  'checklist': ?checklist,
  'notes': ?notes,
};

/// A hand-written [Level2Repository] for cubit tests.
class FakeLevel2Repository implements Level2Repository {
  /// Thrown by the next call when set.
  Exception? error;

  /// What [session] returns.
  Level2Session current = Level2Session.fromJson(sessionJson());

  /// What [checklist] returns.
  List<LocalizedText> template = [
    LocalizedText(en: 'Safe wiring', bn: 'নিরাপদ তার'),
  ];

  /// Calls made, e.g. `schedule`.
  final List<Object> calls = [];

  Future<T> _reply<T>(T value) async {
    final e = error;
    if (e != null) throw e;
    return value;
  }

  @override
  Future<Paged<Level2Row>> sessions({
    String? providerId,
    Level2SessionStatusEnum? status,
    String? cursor,
  }) => _reply(Paged([Level2Row(current)]));

  @override
  Future<Level2Row> session(String id) =>
      _reply(Level2Row(current, providerName: 'Rahim Uddin'));

  @override
  Future<List<AdminProviderSummary>> providers(String query, {int? level}) {
    calls.add('providers $query $level');
    return _reply([AdminProviderSummary.fromJson(providerJson())]);
  }

  @override
  Future<List<LocalizedText>> checklist(String serviceId) => _reply(template);

  @override
  Future<Level2Session> schedule(Level2Booking booking) {
    calls.add(booking);
    return _reply(current);
  }

  @override
  Future<Level2Session> record(String id, Level2ResultInput result) {
    calls.add(result);
    return _reply(
      Level2Session.fromJson(sessionJson(status: 'completed', result: 'pass')),
    );
  }
}
