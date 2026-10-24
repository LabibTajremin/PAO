import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/live/domain/live_repository.dart';

/// [LiveRepository] on the PAO API.
class ApiLiveRepository implements LiveRepository {
  /// Creates the repository.
  ApiLiveRepository(Dio api) : _api = CustomerBookingsApi(api);

  final CustomerBookingsApi _api;

  @override
  Future<Booking> booking(String id) async =>
      (await _api.getCustomerBooking(bookingId: id)).data!;

  @override
  Future<String> startCode(String id) async =>
      (await _api.getStartCode(bookingId: id)).data!.code;

  @override
  Future<Booking> decideExtras(
    String id, {
    required String proposalId,
    required bool approve,
  }) async => (await _api.decideExtras(
    bookingId: id,
    extrasDecisionInput: ExtrasDecisionInput(
      proposalId: proposalId,
      approve: approve,
    ),
  )).data!;
}
