import 'package:dio/dio.dart';
import 'package:pao_admin/features/providers/domain/providers_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [ProvidersRepository] on the PAO API.
class ApiProvidersRepository implements ProvidersRepository {
  /// Creates the repository.
  ApiProvidersRepository(Dio api) : _api = AdminPeopleApi(api);

  final AdminPeopleApi _api;

  @override
  Future<Paged<AdminProviderSummary>> list(
    ProviderFilter filter,
    String? cursor,
  ) async {
    final res = await _api.listAdminProviders(
      q: filter.query,
      status: filter.status?.value,
      level: filter.level,
      flagged: filter.flagged ? true : null,
      cursor: cursor,
    );
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<AdminProviderDetail> detail(String id) async =>
      (await _api.getAdminProvider(providerId: id)).data!;

  @override
  Future<AdminProviderDetail> changeStatus(
    String id,
    AccountStatusChange change,
  ) async => (await _api.changeProviderStatus(
    providerId: id,
    accountStatusChange: change,
  )).data!;
}
