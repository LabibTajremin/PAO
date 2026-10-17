import 'package:dio/dio.dart';
import 'package:pao_admin/features/customers/domain/customers_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [CustomersRepository] on the PAO API.
class ApiCustomersRepository implements CustomersRepository {
  /// Creates the repository.
  ApiCustomersRepository(Dio api) : _api = AdminPeopleApi(api);

  final AdminPeopleApi _api;

  @override
  Future<Paged<AdminCustomerSummary>> list(
    CustomerFilter filter,
    String? cursor,
  ) async {
    final res = await _api.listAdminCustomers(
      q: filter.query,
      status: filter.status?.value,
      cursor: cursor,
    );
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<AdminCustomerDetail> detail(String id) async =>
      (await _api.getAdminCustomer(customerId: id)).data!;

  @override
  Future<AdminCustomerDetail> changeStatus(
    String id,
    AccountStatusChange change,
  ) async => (await _api.changeCustomerStatus(
    customerId: id,
    accountStatusChange: change,
  )).data!;
}
