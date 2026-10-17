import 'package:dio/dio.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/domain/places.dart';

const _envKey = String.fromEnvironment('PAO_MAPS_API_KEY');

/// The maps adapter for this build: Google when `PAO_MAPS_API_KEY` is set,
/// otherwise none, so a build without a key still lets customers type their
/// address.
PlacesService placesFromEnvironment({String key = _envKey, Dio? http}) =>
    key.isEmpty ? const NoPlacesService() : GooglePlacesService(http, key);

/// [PlacesService] on the Google Geocoding API (D10); one call returns both
/// the address text and its position, so no separate details lookup is needed.
class GooglePlacesService implements PlacesService {
  /// Creates the adapter with the maps [key].
  GooglePlacesService(Dio? http, this.key) : _http = http ?? Dio();

  final Dio _http;

  /// Google Maps Platform key.
  final String key;

  static const _url = 'https://maps.googleapis.com/maps/api/geocode/json';

  @override
  Future<List<Place>> search(String query, {String language = 'en'}) =>
      _geocode({
        'address': query,
        'components': 'country:BD',
        'language': language,
      });

  @override
  Future<Place?> reverse(GeoPoint point, {String language = 'en'}) async {
    final found = await _geocode({
      'latlng': '${point.lat},${point.lng}',
      'language': language,
    });
    return found.isEmpty ? null : found.first;
  }

  Future<List<Place>> _geocode(Map<String, String> params) async {
    final res = await _http.get<Map<String, Object?>>(
      _url,
      queryParameters: {...params, 'region': 'bd', 'key': key},
    );
    final results = res.data?['results'];
    if (results is! List<Object?>) return const [];
    return [for (final r in results) ?_place(r)];
  }
}

Place? _place(Object? json) {
  if (json case {
    'formatted_address': final String title,
    'geometry': {'location': {'lat': final num lat, 'lng': final num lng}},
    'address_components': final Object? parts,
  }) {
    return Place(
      title: title,
      area: _area(parts),
      point: GeoPoint(lat.toDouble(), lng.toDouble()),
    );
  }
  return null;
}

String? _area(Object? parts) {
  if (parts is! List<Object?>) return null;
  for (final p in parts) {
    if (p
        case {
          'long_name': final String name,
          'types': final List<Object?> types,
        }
        when types.contains('sublocality') || types.contains('neighborhood')) {
      return name;
    }
  }
  return null;
}
