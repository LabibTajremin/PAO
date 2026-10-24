import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Permission to schedule and record Level 2 sessions (A07).
const level2Permission = 'level2:manage';

/// Permission to look providers up by name.
const providerReadPermission = 'provider:read';

/// Permission to read a service's Level 2 checklist from the catalog.
const catalogReadPermission = 'catalog:read';

/// A session with the provider and service names the session itself leaves
/// out; null names are unknown (no permission or the lookup failed).
class Level2Row {
  /// Creates the row.
  const Level2Row(this.session, {this.providerName, this.serviceName});

  /// The session.
  final Level2Session session;

  /// Provider's name.
  final String? providerName;

  /// Service's name in both languages.
  final LocalizedText? serviceName;
}

/// A new session to book (PRD §6.3).
class Level2Booking {
  /// Creates the booking.
  const Level2Booking({
    required this.providerId,
    required this.serviceId,
    required this.at,
    required this.location,
  });

  /// Provider to test.
  final String providerId;

  /// Service the test covers.
  final String serviceId;

  /// When it starts.
  final DateTime at;

  /// Where it takes place.
  final String location;
}

/// Level 2 skill and field verification (PRD §6.3, A-04).
abstract interface class Level2Repository {
  /// One page of sessions, newest first.
  Future<Paged<Level2Row>> sessions({
    String? providerId,
    Level2SessionStatusEnum? status,
    String? cursor,
  });

  /// One session.
  Future<Level2Row> session(String id);

  /// Providers whose name or phone matches [query]; [level] keeps only
  /// providers at that level.
  Future<List<AdminProviderSummary>> providers(String query, {int? level});

  /// The service's checklist; empty when the catalog cannot be read.
  Future<List<LocalizedText>> checklist(String serviceId);

  /// Books [booking].
  Future<Level2Session> schedule(Level2Booking booking);

  /// Records the outcome of session [id].
  Future<Level2Session> record(String id, Level2ResultInput result);
}
