import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// [BookingRepository] on the PAO API.
class ApiBookingRepository implements BookingRepository {
  /// Creates the repository.
  ApiBookingRepository(Dio api)
    : _customer = CustomerApi(api),
      _bookings = CustomerBookingsApi(api);

  final CustomerApi _customer;
  final CustomerBookingsApi _bookings;

  @override
  Future<BookingOptions> options(String serviceId, String providerId) async {
    // Future.wait rethrows the first failure itself, so the page can explain
    // it, and keeps the other failures from going unhandled.
    final [service, provider, addresses] = await Future.wait<Object?>([
      _customer.getService(serviceId: serviceId),
      _customer.getProviderPublicProfile(providerId: providerId),
      this.addresses(),
    ]);
    return BookingOptions(
      service: (service! as Response<Service>).data!,
      provider: (provider! as Response<ProviderPublicProfile>).data!,
      addresses: addresses! as List<Address>,
    );
  }

  @override
  Future<List<Address>> addresses() async {
    final items = (await _customer.listAddresses()).data!.items;
    bool isDefault(Address a) => a.isDefault ?? false;
    return [...items.where(isDefault), ...items.where((a) => !isDefault(a))];
  }

  @override
  Future<Booking> create(BookingCreate request, {required String key}) async =>
      (await _bookings.createBooking(
        idempotencyKey: key,
        bookingCreate: request,
      )).data!;

  @override
  Future<Booking> booking(String id) async =>
      (await _bookings.getCustomerBooking(bookingId: id)).data!;
}
