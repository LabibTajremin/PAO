import 'package:dio/dio.dart';
import 'package:pao_admin/features/dashboard/domain/dashboard_repository.dart';
import 'package:pao_api/pao_api.dart';

/// [DashboardRepository] on the PAO API.
class ApiDashboardRepository implements DashboardRepository {
  /// Creates the repository.
  ApiDashboardRepository(Dio api) : _api = AdminApi(api);

  final AdminApi _api;

  @override
  Future<Dashboard> load() async => (await _api.getDashboard()).data!;
}
