import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/service/domain/service_repository.dart';

/// [ServiceRepository] on the PAO API.
class ApiServiceRepository implements ServiceRepository {
  /// Creates the repository.
  ApiServiceRepository(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;

  @override
  Future<Service> service(String id) async =>
      (await _api.getService(serviceId: id)).data!;
}
