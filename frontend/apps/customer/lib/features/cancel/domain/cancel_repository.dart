import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// Cancelling a booking before the job starts (C-10).
abstract interface class CancelRepository implements BookingReader {
  /// Cancels with [reason] and an optional [note].
  Future<Booking> cancel(
    String id,
    CustomerCancelInputReasonEnum reason,
    String? note,
  );
}
