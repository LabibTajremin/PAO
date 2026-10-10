import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/shared/booking_draft.dart';

/// How the nearby list is ordered (C-05).
enum ProviderSort {
  /// Closest first.
  distance,

  /// Best rated first.
  rating,
}

/// Sort and filters of the provider list (C40).
class ProviderQuery {
  /// Creates the query.
  const ProviderQuery({
    this.sort = ProviderSort.distance,
    this.topRated = false,
    this.proOnly = false,
  });

  /// The order.
  final ProviderSort sort;

  /// Only providers rated 4 stars or more.
  final bool topRated;

  /// Only PAO Verified Pro providers.
  final bool proOnly;

  /// Whether [card] passes the filters.
  bool keeps(ProviderCard card) =>
      (!topRated || card.rating >= 4) &&
      (!proOnly || card.badge == Badge.verifiedPro);
}

/// One page of nearby providers with the price of the selection.
class NearbyPage {
  /// Creates the page.
  const NearbyPage(this.items, this.summary, [this.next]);

  /// Provider cards.
  final List<ProviderCard> items;

  /// The fixed price of the chosen sub-service and quantity.
  final PriceSummary summary;

  /// Cursor of the next page.
  final String? next;
}

/// A provider's profile with its latest reviews (C11).
class ProviderOverview {
  /// Creates the overview.
  const ProviderOverview(this.profile, this.reviews);

  /// The public profile.
  final ProviderPublicProfile profile;

  /// The latest reviews.
  final List<Review> reviews;
}

/// Finding and presenting providers (C-05, C-06).
abstract interface class ProvidersRepository {
  /// The address providers are searched around, or null without one.
  Future<Address?> searchAddress();

  /// Providers near [addressId] for the first item of [draft].
  Future<NearbyPage> nearby({
    required BookingDraft draft,
    required String addressId,
    required ProviderSort sort,
    String? cursor,
  });

  /// The profile of provider [id] with its latest reviews.
  Future<ProviderOverview> overview(String id);

  /// A page of reviews of provider [id].
  Future<Paged<Review>> reviews(String id, {String? cursor});
}
