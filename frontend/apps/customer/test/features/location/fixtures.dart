import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/domain/places.dart';

/// IDs of saved addresses.
const homeAddressId = 'a0000000-0000-4000-8000-000000000001';

/// The second saved address.
const officeAddressId = 'a0000000-0000-4000-8000-000000000002';

/// A saved address.
Map<String, Object?> address({
  String id = homeAddressId,
  String label = 'home',
  String line1 = 'House 12, Road 5, Block C',
  String? area = 'Banani',
  bool isDefault = true,
}) => {
  'id': id,
  'label': label,
  'line1': line1,
  'line2': 'Flat 3B',
  'area': ?area,
  'location': {'lat': 23.794, 'lng': 90.407},
  'isDefault': isDefault,
};

/// `GET /v1/customer/addresses`.
Map<String, Object?> addressList(List<Map<String, Object?>> items) => {
  'items': items,
};

/// `GET /v1/customer/service-area`.
Map<String, Object?> coverage({bool covered = true, String? area = 'Dhaka'}) =>
    {'covered': covered, 'areaName': ?area};

/// A searched place in Banani.
const banani = Place(
  title: 'Road 11, Banani, Dhaka',
  area: 'Banani',
  point: GeoPoint(23.79, 90.40),
);

/// The place at the device position.
const gulshan = Place(
  title: 'House 5, Road 2, Gulshan',
  area: 'Gulshan',
  point: GeoPoint(23.794, 90.407),
);

/// Maps port stand-in.
class FakePlaces implements PlacesService {
  /// What [search] finds.
  List<Place> found = [banani];

  /// What [reverse] finds.
  Place? here = gulshan;

  /// Makes every call fail.
  bool fail = false;

  /// Queries searched, with their language.
  final queries = <String>[];

  @override
  Future<List<Place>> search(String query, {String language = 'en'}) async {
    queries.add('$language:$query');
    if (fail) throw const NetworkFailure();
    return found;
  }

  @override
  Future<Place?> reverse(GeoPoint point, {String language = 'en'}) async {
    if (fail) throw const NetworkFailure();
    return here;
  }
}
