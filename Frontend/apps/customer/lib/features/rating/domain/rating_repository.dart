import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// The customer's rating of a provider (C-11).
class ProviderReview {
  /// Creates the review.
  const ProviderReview({
    required this.stars,
    this.tags = const {},
    this.comment = '',
  });

  /// 1 to 5.
  final int stars;

  /// Fixed tags from the API's list.
  final Set<ReviewTag> tags;

  /// Optional free text.
  final String comment;
}

/// Rating a completed booking's provider.
abstract interface class RatingRepository implements BookingReader {
  /// Sends [review] for booking [id].
  Future<void> review(String id, ProviderReview review);
}
