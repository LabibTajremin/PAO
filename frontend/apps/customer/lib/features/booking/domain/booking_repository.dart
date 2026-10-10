import 'package:pao_api/pao_api.dart';

/// Reads one of the customer's bookings; the waiting, live, cancel and rating
/// screens all start from it.
abstract interface class BookingReader {
  /// The booking with its timeline, provider and pending extras.
  Future<Booking> booking(String id);
}

/// What the set-up screen shows before the customer confirms (C12).
class BookingOptions {
  /// Creates the options.
  const BookingOptions({
    required this.service,
    required this.provider,
    required this.addresses,
  });

  /// The service with its sub-services and prices.
  final Service service;

  /// The chosen provider.
  final ProviderPublicProfile provider;

  /// Saved addresses, default first.
  final List<Address> addresses;
}

/// Booking set-up and creation (C-07).
abstract interface class BookingRepository implements BookingReader {
  /// Loads the service, the provider and the saved addresses.
  Future<BookingOptions> options(String serviceId, String providerId);

  /// Saved addresses, default first; reloaded after adding one.
  Future<List<Address>> addresses();

  /// Requests the booking; repeating it with the same [key] returns the first
  /// result instead of a second booking.
  Future<Booking> create(BookingCreate request, {required String key});
}
