import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';

/// [BookingsRepository] on the PAO API.
class ApiBookingsRepository implements BookingsRepository {
  /// Creates the repository.
  ApiBookingsRepository(Dio api) : _api = CustomerBookingsApi(api);

  final CustomerBookingsApi _api;

  @override
  Future<Paged<BookingSummary>> list(BookingsTab tab, {String? cursor}) async {
    final res = await _api.listCustomerBookings(tab: tab.name, cursor: cursor);
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<Booking> booking(String id) async =>
      (await _api.getCustomerBooking(bookingId: id)).data!;

  @override
  Future<Receipt> receipt(String id) async =>
      (await _api.getCustomerReceipt(bookingId: id)).data!;
}
