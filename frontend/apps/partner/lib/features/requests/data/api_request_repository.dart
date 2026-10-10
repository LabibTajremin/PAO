import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/requests/domain/request_repository.dart';

/// [RequestRepository] on the PAO API.
class ApiRequestRepository implements RequestRepository {
  /// Creates the repository.
  ApiRequestRepository(Dio api) : _api = ProviderJobsApi(api);

  final ProviderJobsApi _api;

  @override
  Future<Booking> request(String id) async =>
      (await _api.getProviderJob(bookingId: id)).data!;

  @override
  Future<Booking> accept(String id) async =>
      (await _api.acceptRequest(bookingId: id)).data!;

  @override
  Future<Booking> reject(
    String id,
    RejectInputReasonEnum reason,
    String? note,
  ) async => (await _api.rejectRequest(
    bookingId: id,
    rejectInput: RejectInput(reason: reason, note: note),
  )).data!;
}
