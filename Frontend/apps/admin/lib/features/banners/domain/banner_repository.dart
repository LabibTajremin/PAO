import 'package:pao_api/pao_api.dart';

/// Home banners as admins manage them (C07 content).
abstract interface class BannerRepository {
  /// Every banner, published or not, in display order.
  Future<List<Banner>> list();

  /// Every service, for the banner's link.
  Future<List<Service>> services();

  /// Creates a banner when [id] is null, otherwise replaces it.
  Future<Banner> save(String? id, BannerInput input);

  /// Removes a banner.
  Future<void> delete(String id);
}
