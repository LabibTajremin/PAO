import 'package:dio/dio.dart';
import 'package:pao_admin/features/banners/domain/banner_repository.dart';
import 'package:pao_api/pao_api.dart';

/// [BannerRepository] on the PAO API.
class ApiBannerRepository implements BannerRepository {
  /// Creates the repository.
  ApiBannerRepository(Dio api) : _api = AdminCatalogApi(api);

  final AdminCatalogApi _api;

  @override
  Future<List<Banner>> list() async => (await _api.listBanners()).data!.banners;

  @override
  Future<List<Service>> services() async => [
    for (final c in (await _api.getAdminCatalog()).data!.categories)
      ...c.services,
  ];

  @override
  Future<Banner> save(String? id, BannerInput input) async {
    final res = id == null
        ? await _api.createBanner(bannerInput: input)
        : await _api.updateBanner(bannerId: id, bannerInput: input);
    return res.data!;
  }

  @override
  Future<void> delete(String id) => _api.deleteBanner(bannerId: id);
}
