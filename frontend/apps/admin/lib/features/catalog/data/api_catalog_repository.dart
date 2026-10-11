import 'package:dio/dio.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_api/pao_api.dart';

/// [CatalogRepository] on the PAO API.
class ApiCatalogRepository implements CatalogRepository {
  /// Creates the repository.
  ApiCatalogRepository(Dio api) : _api = AdminCatalogApi(api);

  final AdminCatalogApi _api;

  @override
  Future<CatalogTree> tree() async => (await _api.getAdminCatalog()).data!;

  @override
  Future<Category> saveCategory(String? id, CategoryInput input) async {
    final res = id == null
        ? await _api.createCategory(categoryInput: input)
        : await _api.updateCategory(categoryId: id, categoryInput: input);
    return res.data!;
  }

  @override
  Future<Service> saveService(String? id, ServiceInput input) async {
    final res = id == null
        ? await _api.createService(serviceInput: input)
        : await _api.updateService(serviceId: id, serviceInput: input);
    return res.data!;
  }

  @override
  Future<SubService> saveSubService(String? id, SubServiceInput input) async {
    final res = id == null
        ? await _api.createSubService(subServiceInput: input)
        : await _api.updateSubService(subServiceId: id, subServiceInput: input);
    return res.data!;
  }

  @override
  Future<List<PriceVersion>> prices(String subServiceId) async =>
      (await _api.listPriceHistory(subServiceId: subServiceId)).data!.items;

  @override
  Future<PriceVersion> changePrice(String subServiceId, int amount) async =>
      (await _api.changePrice(
        subServiceId: subServiceId,
        priceInput: PriceInput(amount: amount),
      )).data!;
}
