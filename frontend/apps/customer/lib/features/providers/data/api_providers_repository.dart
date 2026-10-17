import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/data/api_address_repository.dart';
import 'package:pao_customer/features/location/domain/address_repository.dart';
import 'package:pao_customer/features/providers/domain/providers_repository.dart';
import 'package:pao_customer/shared/booking_draft.dart';

/// How many reviews the profile shows before "All reviews".
const recentReviews = 3;

/// [ProvidersRepository] on the PAO API.
class ApiProvidersRepository implements ProvidersRepository {
  /// Creates the repository.
  ApiProvidersRepository(Dio api)
    : _api = CustomerApi(api),
      _addresses = ApiAddressRepository(api);

  final CustomerApi _api;
  final AddressRepository _addresses;

  @override
  Future<Address?> searchAddress() async => defaultOf(await _addresses.list());

  @override
  Future<NearbyPage> nearby({
    required BookingDraft draft,
    required String addressId,
    required ProviderSort sort,
    String? cursor,
  }) async {
    // The search takes one sub-service; the first chosen item stands for the
    // booking, and the rest are priced again when it is created.
    final item = draft.items.entries.first;
    final res = await _api.findNearbyProviders(
      serviceId: draft.serviceId,
      subServiceId: item.key,
      quantity: item.value,
      addressId: addressId,
      sort: sort.name,
      cursor: cursor,
    );
    final body = res.data!;
    return NearbyPage(body.items, body.priceSummary, body.nextCursor);
  }

  @override
  Future<ProviderOverview> overview(String id) async {
    final parts = await Future.wait<Object>([
      _api.getProviderPublicProfile(providerId: id),
      _api.listProviderReviews(providerId: id, limit: recentReviews),
    ]);
    return ProviderOverview(
      (parts[0] as Response<ProviderPublicProfile>).data!,
      (parts[1] as Response<ReviewList>).data!.items,
    );
  }

  @override
  Future<Paged<Review>> reviews(String id, {String? cursor}) async {
    final res = await _api.listProviderReviews(providerId: id, cursor: cursor);
    return Paged(res.data!.items, res.data!.nextCursor);
  }
}
