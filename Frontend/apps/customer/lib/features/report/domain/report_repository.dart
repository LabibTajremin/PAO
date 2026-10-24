import 'dart:typed_data';

import 'package:pao_api/pao_api.dart';

/// Reasons a customer can report; the others in [ComplaintReason] are
/// providers' complaints about customers.
const List<ComplaintReason> customerReasons = [
  ComplaintReason.noShow,
  ComplaintReason.late_,
  ComplaintReason.poorQuality,
  ComplaintReason.overcharge,
  ComplaintReason.damage,
  ComplaintReason.behaviour,
  ComplaintReason.safety,
  ComplaintReason.payment,
  ComplaintReason.other,
];

/// A problem the customer reports about a booking (C-14).
class ProblemReport {
  /// Creates the report.
  const ProblemReport({
    required this.reason,
    required this.description,
    this.photoIds = const [],
  });

  /// Why the customer is reporting.
  final ComplaintReason reason;

  /// What happened, 10–1000 characters.
  final String description;

  /// Uploaded photo media IDs.
  final List<String> photoIds;
}

/// Reporting a problem on a booking (C20).
abstract interface class ReportRepository {
  /// Uploads a photo and returns its media ID.
  Future<String> uploadPhoto(Uint8List bytes);

  /// Files [report] and returns the support ticket number.
  Future<String> report(String bookingId, ProblemReport report);
}
