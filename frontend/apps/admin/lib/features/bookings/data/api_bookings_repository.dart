import 'package:dio/dio.dart';
import 'package:pao_admin/features/bookings/domain/bookings_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [BookingsRepository] on the PAO API.
class ApiBookingsRepository implements BookingsRepository {
  /// Creates the repository.
  ApiBookingsRepository(Dio api) : _api = AdminBookingsApi(api);

  final AdminBookingsApi _api;

  @override
  Future<Paged<BookingSummary>> list(
    BookingFilter filter,
    String? cursor,
  ) async {
    final res = await _api.listAdminBookings(
      status: filter.status?.value,
      from: filter.from,
      to: filter.to,
      area: filter.area,
      cursor: cursor,
    );
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<Booking> detail(String id) async =>
      (await _api.getAdminBooking(bookingId: id)).data!;
}
