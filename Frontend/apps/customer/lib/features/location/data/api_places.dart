import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/domain/places.dart';

/// [PlacesService] on PAO's own OpenStreetMap copy of Dhaka (ADR-0042), so
/// no search leaves PAO and no maps key is needed.
class ApiPlacesService implements PlacesService {
  /// Creates the adapter on the signed-in [http] client.
  ApiPlacesService(Dio http) : _api = PlacesApi(http);

  final PlacesApi _api;

  @override
  Future<List<Place>> search(String query, {String language = 'en'}) async {
    final res = await _api.searchPlaces(q: query, lang: language);
    return [for (final p in res.data!.items) _place(p)];
  }

  @override
  Future<Place?> reverse(GeoPoint point, {String language = 'en'}) async {
    try {
      final res = await _api.reversePlace(
        lat: point.lat,
        lng: point.lng,
        lang: language,
      );
      return _place(res.data!);
    } on DioException catch (e) {
      // Nothing named nearby (404) or outside the launch area (422): the
      // customer types the address, and the coverage note says "coming soon".
      final status = e.response?.statusCode;
      if (status == 404 || status == 422) return null;
      rethrow;
    }
  }
}

Place _place(MapPlace p) => Place(
  title: p.title,
  area: p.area,
  point: GeoPoint(p.location.lat, p.location.lng),
);
