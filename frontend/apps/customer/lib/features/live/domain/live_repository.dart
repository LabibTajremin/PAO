import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// The customer's side of an active booking (C-08, C-09).
abstract interface class LiveRepository implements BookingReader {
  /// The 4-digit code the provider needs to start the job.
  Future<String> startCode(String id);

  /// Approves or declines the pending extras [proposalId].
  Future<Booking> decideExtras(
    String id, {
    required String proposalId,
    required bool approve,
  });
}
