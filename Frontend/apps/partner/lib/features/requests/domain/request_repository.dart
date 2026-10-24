import 'package:pao_api/pao_api.dart';

/// Answering an incoming booking request (P-05).
abstract interface class RequestRepository {
  /// The request; only the area is shown before acceptance (PRD §11).
  Future<Booking> request(String id);

  /// Accepts before the deadline.
  Future<Booking> accept(String id);

  /// Rejects with [reason].
  Future<Booking> reject(String id, RejectInputReasonEnum reason, String? note);
}
