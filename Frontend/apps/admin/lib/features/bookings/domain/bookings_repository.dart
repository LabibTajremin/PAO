import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the bookings monitor (A10) is narrowed to.
class BookingFilter {
  /// Creates the filter; the defaults show every booking.
  const BookingFilter({this.status, this.from, this.to, this.area});

  /// Booking status.
  final BookingStatus? status;

  /// Created on or after this Asia/Dhaka date, `yyyy-MM-dd`.
  final String? from;

  /// Created on or before this Asia/Dhaka date, `yyyy-MM-dd`.
  final String? to;

  /// Area name, e.g. Banani.
  final String? area;

  /// This filter with [status] instead.
  BookingFilter withStatus(BookingStatus? status) =>
      BookingFilter(status: status, from: from, to: to, area: area);

  /// This filter created between [from] and [to]; nulls clear the range.
  BookingFilter between(String? from, String? to) =>
      BookingFilter(status: status, from: from, to: to, area: area);

  /// This filter in area [text]; blank clears the area.
  BookingFilter inArea(String text) => BookingFilter(
    status: status,
    from: from,
    to: to,
    area: text.trim().isEmpty ? null : text.trim(),
  );
}

/// Every booking on the platform, for admins (A-06).
abstract interface class BookingsRepository {
  /// One page of bookings matching [filter], newest first.
  Future<Paged<BookingSummary>> list(BookingFilter filter, String? cursor);

  /// A booking with both parties and the full timeline.
  Future<Booking> detail(String id);
}
