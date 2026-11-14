import 'package:pao_admin/features/banners/domain/banner_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the banners page shows: the banners and the services they may open.
class BannersData {
  /// Creates the data.
  const BannersData(this.banners, this.services);

  /// Every banner in display order.
  final List<Banner> banners;

  /// Every service.
  final List<Service> services;
}

/// The banners page: the list, saves and deletes, each followed by a reload.
class BannersCubit extends LoadCubit<BannersData> {
  /// Creates the cubit; call [load] to start.
  BannersCubit(this._repo)
    : super(
        () async => BannersData(await _repo.list(), await _repo.services()),
      );

  final BannerRepository _repo;

  /// Creates ([id] null) or updates a banner.
  Future<AppFailure?> save(String? id, BannerInput input) =>
      _then(() => _repo.save(id, input));

  /// Removes a banner.
  Future<AppFailure?> delete(String id) => _then(() => _repo.delete(id));

  Future<AppFailure?> _then(Future<void> Function() action) async {
    final failure = await attempt(action);
    if (failure == null) await refresh();
    return failure;
  }
}
