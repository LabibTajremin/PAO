import 'package:pao_core/pao_core.dart';

/// A place found by text search or from a map position.
class Place {
  /// Creates a place.
  const Place({required this.title, required this.point, this.area});

  /// The formatted address, e.g. "Road 11, Banani, Dhaka".
  final String title;

  /// Neighbourhood or area, e.g. "Banani", when known.
  final String? area;

  /// Where it is.
  final GeoPoint point;
}

/// The maps port (D10): address search and reverse lookup.
abstract interface class PlacesService {
  /// Places matching [query], best first.
  Future<List<Place>> search(String query, {String language = 'en'});

  /// The place at [point], or null when unknown.
  Future<Place?> reverse(GeoPoint point, {String language = 'en'});
}

/// Used without a maps key: nothing is found and the customer types the
/// address by hand.
class NoPlacesService implements PlacesService {
  /// Creates the service.
  const NoPlacesService();

  @override
  Future<List<Place>> search(String query, {String language = 'en'}) async =>
      const [];

  @override
  Future<Place?> reverse(GeoPoint point, {String language = 'en'}) async =>
      null;
}

/// Central Dhaka, where the pin starts when the device position is unknown.
const dhakaCentre = GeoPoint(23.8103, 90.4125);
