import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/home/domain/home_repository.dart';
import 'package:pao_customer/features/location/data/api_address_repository.dart';
import 'package:pao_customer/features/location/domain/address_repository.dart';

/// [CatalogRepository] on the PAO API.
class ApiCatalogRepository implements CatalogRepository {
  /// Creates the repository.
  ApiCatalogRepository(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;

  @override
  Future<List<Category>> categories() async =>
      publishedOf((await _api.getCatalog()).data!);
}

/// [HomeRepository] on the PAO API.
class ApiHomeRepository implements HomeRepository {
  /// Creates the repository.
  ApiHomeRepository(Dio api)
    : _addresses = ApiAddressRepository(api),
      _catalog = ApiCatalogRepository(api),
      _bookings = CustomerBookingsApi(api);

  final AddressRepository _addresses;
  final CatalogRepository _catalog;
  final CustomerBookingsApi _bookings;

  @override
  Future<HomeData> load() async {
    final parts = await Future.wait<Object?>([
      _addresses.list(),
      _catalog.categories(),
      _quietly(_active),
    ]);
    final addresses = parts[0]! as List<Address>;
    final current = defaultOf(addresses);
    return HomeData(
      addresses: addresses,
      categories: parts[1]! as List<Category>,
      active: parts[2] as BookingSummary?,
      coverage: current == null
          ? null
          : await _quietly(
              () => _addresses.coverage(
                GeoPoint(current.location.lat, current.location.lng),
              ),
            ),
    );
  }

  @override
  Future<void> makeDefault(String addressId) =>
      _addresses.makeDefault(addressId);

  Future<BookingSummary?> _active() async => activeOf(
    (await _bookings.listCustomerBookings(tab: 'upcoming')).data!.items,
  );

  /// The banner and the area check only add to home: when they fail the
  /// customer still sees the catalog.
  Future<T?> _quietly<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on Object {
      return null;
    }
  }
}
