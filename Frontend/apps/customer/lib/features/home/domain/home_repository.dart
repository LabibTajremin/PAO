import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/location/domain/address_repository.dart';

/// Everything the home screen shows (C07, C35).
class HomeData {
  /// Creates the data.
  const HomeData({
    required this.addresses,
    required this.categories,
    this.active,
    this.coverage,
  });

  /// Saved addresses.
  final List<Address> addresses;

  /// Published categories in display order.
  final List<Category> categories;

  /// A booking still in progress, if any.
  final BookingSummary? active;

  /// Whether PAO works at the current address; null when unknown.
  final ServiceAreaCheck? coverage;

  /// The address services are shown for.
  Address? get current => defaultOf(addresses);
}

/// Loads the home screen and switches the current address.
abstract interface class HomeRepository {
  /// Loads addresses, catalog, the active booking and coverage.
  Future<HomeData> load();

  /// Makes [addressId] the current address.
  Future<void> makeDefault(String addressId);
}

/// The published catalog.
abstract interface class CatalogRepository {
  /// Published categories in display order, each with its published services.
  Future<List<Category>> categories();
}

const Set<BookingStatus> _active = {
  BookingStatus.requested,
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
  BookingStatus.inProgress,
};

/// The first booking in [items] that is still running.
BookingSummary? activeOf(List<BookingSummary> items) {
  for (final b in items) {
    if (_active.contains(b.status)) return b;
  }
  return null;
}

/// The booking screen that follows [status]: waiting while the provider has
/// not answered, otherwise the live tracker.
String activePart(BookingStatus status) =>
    status == BookingStatus.requested ? 'waiting' : 'live';

/// Only the published parts of [tree], in display order.
List<Category> publishedOf(CatalogTree tree) {
  final categories = [
    for (final c in tree.categories)
      if (c.published)
        c.copyWith(
          services: [
            for (final s in c.services)
              if (s.published) s,
          ],
        ),
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return [
    for (final c in categories)
      if (c.services.isNotEmpty) c,
  ];
}
