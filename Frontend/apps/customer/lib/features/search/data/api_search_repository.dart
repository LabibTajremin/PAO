import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/search/domain/search_repository.dart';

/// [SearchRepository] on the PAO API.
class ApiSearchRepository implements SearchRepository {
  /// Creates the repository.
  ApiSearchRepository(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;

  @override
  Future<CatalogSearchResults> search(String query) async =>
      (await _api.searchCatalog(q: query)).data!;
}
