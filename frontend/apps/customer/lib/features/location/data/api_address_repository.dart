import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/domain/address_repository.dart';

/// [AddressRepository] on the PAO API.
class ApiAddressRepository implements AddressRepository {
  /// Creates the repository.
  ApiAddressRepository(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;

  @override
  Future<List<Address>> list() async =>
      (await _api.listAddresses()).data!.items;

  @override
  Future<Address> create(AddressDraft draft) async {
    final first = (await list()).isEmpty;
    final res = await _api.createAddress(
      addressInput: _input(draft, isDefault: first),
    );
    return res.data!;
  }

  @override
  Future<Address> update(
    String id,
    AddressDraft draft, {
    bool? isDefault,
  }) async {
    final res = await _api.updateAddress(
      addressId: id,
      addressInput: _input(draft, isDefault: isDefault),
    );
    return res.data!;
  }

  @override
  Future<void> makeDefault(String id) => _api.setDefaultAddress(addressId: id);

  @override
  Future<ServiceAreaCheck> coverage(GeoPoint point) async =>
      (await _api.checkServiceArea(lat: point.lat, lng: point.lng)).data!;

  AddressInput _input(AddressDraft d, {bool? isDefault}) => AddressInput(
    label: d.label,
    line1: d.line1.trim(),
    line2: _optional(d.line2),
    area: _optional(d.area),
    location: Point(lat: d.point.lat, lng: d.point.lng),
    isDefault: isDefault,
  );

  String? _optional(String text) => text.trim().isEmpty ? null : text.trim();
}
