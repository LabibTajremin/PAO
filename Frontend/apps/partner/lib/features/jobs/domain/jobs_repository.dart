import 'dart:typed_data';

import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The lists of M23.
enum JobsTab {
  /// Accepted jobs that have not finished.
  upcoming,

  /// Completed, cancelled and expired jobs.
  past,
}

/// Statuses in which the job is still being worked on (PRD §5).
const Set<BookingStatus> activeStatuses = {
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
  BookingStatus.inProgress,
};

/// A problem the provider reports about a job (M25).
class ProblemReport {
  /// Creates the report.
  const ProblemReport({
    required this.reason,
    required this.description,
    this.photoIds = const [],
  });

  /// Why the provider is reporting.
  final ComplaintReason reason;

  /// What happened, 10–1000 characters.
  final String description;

  /// Uploaded photo media IDs.
  final List<String> photoIds;
}

/// The provider's job history (P-08).
abstract interface class JobsRepository {
  /// One page of [tab].
  Future<Paged<BookingSummary>> list(JobsTab tab, {String? cursor});

  /// The job with its items and timeline.
  Future<Booking> job(String id);

  /// The receipt of a completed job.
  Future<Receipt> receipt(String id);
}

/// Reporting a problem on a job (M25).
abstract interface class ReportRepository {
  /// Uploads a photo and returns its media ID.
  Future<String> uploadPhoto(Uint8List bytes);

  /// Files [report] and returns the support ticket number.
  Future<String> report(String bookingId, ProblemReport report);
}
