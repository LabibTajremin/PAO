import 'package:pao_api/pao_api.dart';

/// Catalog search in Bangla or English (C08).
abstract interface class SearchRepository {
  /// Services and sub-services matching [query].
  Future<CatalogSearchResults> search(String query);
}
