import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the dashboard shows (M15).
class HomeSummary {
  /// Creates the summary.
  const HomeSummary({
    required this.earnedToday,
    required this.jobsToday,
    required this.requests,
    this.active,
  });

  /// Today's earnings in paisa (Asia/Dhaka day).
  final int earnedToday;

  /// Jobs completed today.
  final int jobsToday;

  /// The job in hand, if any.
  final BookingSummary? active;

  /// Requests waiting for an answer.
  final List<BookingSummary> requests;
}

/// Presence and the dashboard (P-04).
abstract interface class HomeRepository {
  /// Today's earnings, the active job and open requests.
  Future<HomeSummary> summary();

  /// Goes online at [at]; returns how often to send heartbeats.
  Future<Duration> goOnline(GeoPoint at);

  /// Goes offline; the server stops storing the location.
  Future<void> goOffline();

  /// Reports the position while online.
  Future<void> heartbeat(GeoPoint at);
}

const List<BookingStatus> _progress = [
  BookingStatus.inProgress,
  BookingStatus.arrived,
  BookingStatus.onTheWay,
  BookingStatus.accepted,
];

/// The job furthest along among [jobs], which is the one the provider is on.
BookingSummary? activeJob(List<BookingSummary> jobs) {
  for (final status in _progress) {
    final job = jobs.where((j) => j.status == status).firstOrNull;
    if (job != null) return job;
  }
  return null;
}
