import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The catalog tree (A03) and category edits.
class CatalogCubit extends LoadCubit<CatalogTree> {
  /// Creates the cubit; call [load] to start.
  CatalogCubit(this._repo) : super(_repo.tree);

  final CatalogRepository _repo;

  /// Creates ([id] null) or updates a category, then reloads the tree.
  Future<AppFailure?> saveCategory(String? id, CategoryInput input) async {
    final failure = await attempt(() => _repo.saveCategory(id, input));
    if (failure == null) await refresh();
    return failure;
  }
}

/// What the service editor works on: the categories to file it under and
/// the service itself, null while creating one.
class ServiceEditorData {
  /// Creates the data.
  const ServiceEditorData(this.categories, this.service);

  /// Every category.
  final List<Category> categories;

  /// The service being edited.
  final Service? service;
}

/// The service editor (A04): the service, its sub-services and their prices.
class ServiceEditorCubit extends LoadCubit<ServiceEditorData> {
  /// Creates the cubit for [serviceId], or for a new service when null.
  ServiceEditorCubit(CatalogRepository repo, String? serviceId)
    : _repo = repo,
      super(() => _find(repo, serviceId));

  final CatalogRepository _repo;

  /// The repository, for the price panel.
  CatalogRepository get repository => _repo;

  // There is no single-service endpoint; the admin tree is small and cached.
  static Future<ServiceEditorData> _find(
    CatalogRepository repo,
    String? id,
  ) async {
    final categories = (await repo.tree()).categories;
    if (id == null) return ServiceEditorData(categories, null);
    final service = categories
        .expand((c) => c.services)
        .where((s) => s.id == id)
        .firstOrNull;
    if (service == null) throw const ApiFailure('NOT_FOUND', status: 404);
    return ServiceEditorData(categories, service);
  }

  /// Creates ([id] null) or updates the service; returns it, or why not.
  Future<(Service?, AppFailure?)> saveService(
    String? id,
    ServiceInput input,
  ) async {
    Service? saved;
    final failure = await attempt(
      () async => saved = await _repo.saveService(id, input),
    );
    if (failure == null && id != null) await refresh();
    return (saved, failure);
  }

  /// Creates ([id] null) or updates a sub-service, then reloads.
  Future<AppFailure?> saveSubService(String? id, SubServiceInput input) async {
    final failure = await attempt(() => _repo.saveSubService(id, input));
    if (failure == null) await refresh();
    return failure;
  }
}

/// Price versions of one sub-service, newest first, and price changes.
class PriceCubit extends LoadCubit<List<PriceVersion>> {
  /// Creates the cubit for [subServiceId].
  PriceCubit(CatalogRepository repo, String subServiceId)
    : _repo = repo,
      _id = subServiceId,
      super(() => _newestFirst(repo, subServiceId));

  final CatalogRepository _repo;
  final String _id;

  static Future<List<PriceVersion>> _newestFirst(
    CatalogRepository repo,
    String id,
  ) async =>
      [...await repo.prices(id)]
        ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));

  /// Sets a new price of [amount] paisa, then reloads the history.
  Future<AppFailure?> change(int amount) async {
    final failure = await attempt(() => _repo.changePrice(_id, amount));
    if (failure == null) await refresh();
    return failure;
  }
}
