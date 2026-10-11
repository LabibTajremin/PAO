import 'package:pao_api/pao_api.dart';

/// The catalog as admins edit it: categories, services, sub-services and
/// versioned prices (PRD §4, A-02).
abstract interface class CatalogRepository {
  /// The whole tree, unpublished items included.
  Future<CatalogTree> tree();

  /// Creates a category when [id] is null, otherwise replaces it.
  Future<Category> saveCategory(String? id, CategoryInput input);

  /// Creates a service when [id] is null, otherwise replaces it.
  Future<Service> saveService(String? id, ServiceInput input);

  /// Creates a sub-service when [id] is null, otherwise replaces it.
  Future<SubService> saveSubService(String? id, SubServiceInput input);

  /// Price versions of a sub-service.
  Future<List<PriceVersion>> prices(String subServiceId);

  /// Sets a new price in paisa; it applies to bookings made from now on.
  Future<PriceVersion> changePrice(String subServiceId, int amount);
}
