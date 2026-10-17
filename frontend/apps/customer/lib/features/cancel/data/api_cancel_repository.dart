import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/cancel/domain/cancel_repository.dart';

/// [CancelRepository] on the PAO API.
class ApiCancelRepository implements CancelRepository {
  /// Creates the repository.
  ApiCancelRepository(Dio api) : _api = CustomerBookingsApi(api);

  final CustomerBookingsApi _api;

  @override
  Future<Booking> booking(String id) async =>
      (await _api.getCustomerBooking(bookingId: id)).data!;

  @override
  Future<Booking> cancel(
    String id,
    CustomerCancelInputReasonEnum reason,
    String? note,
  ) async => (await _api.cancelCustomerBooking(
    bookingId: id,
    customerCancelInput: CustomerCancelInput(reason: reason, note: note),
  )).data!;
}
