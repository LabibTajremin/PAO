import 'dart:typed_data';

import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The two lists of C18.
enum BookingsTab {
  /// Bookings waiting for a reply or not finished yet.
  upcoming,

  /// Completed, cancelled, declined and expired bookings (C18b).
  past,
}

/// Statuses in which the provider is on the job, followed on the live screen
/// (C14).
const Set<BookingStatus> liveStatuses = {
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
  BookingStatus.inProgress,
};

/// Statuses that ended without the job being done (C57).
const Set<BookingStatus> endedStatuses = {
  BookingStatus.rejected,
  BookingStatus.timedOut,
  BookingStatus.cancelled,
};

/// Hands a file to another app through the system share sheet.
typedef ShareFile = Future<void> Function(Uint8List bytes, String name);

/// The customer's booking history (C-12).
abstract interface class BookingsRepository {
  /// One page of [tab].
  Future<Paged<BookingSummary>> list(BookingsTab tab, {String? cursor});

  /// The booking with its items, provider and timeline.
  Future<Booking> booking(String id);

  /// The receipt of a completed booking.
  Future<Receipt> receipt(String id);
}
