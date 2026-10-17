import 'package:pao_api/pao_api.dart';

/// The provider's rating of a customer (P-09).
class CustomerReview {
  /// Creates the review.
  const CustomerReview({
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

/// Provider actions on one job after acceptance (P-06, P-07, P-09).
abstract interface class JobRepository {
  /// The job, with the customer's contact once accepted.
  Future<Booking> job(String id);

  /// Marks "On the way".
  Future<Booking> onTheWay(String id);

  /// Marks "Arrived".
  Future<Booking> arrived(String id);

  /// Cancels after acceptance; it counts against the provider's ranking.
  Future<Booking> cancel(
    String id,
    ProviderCancelInputReasonEnum reason,
    String? note,
  );

  /// Starts the job with the customer's 4-digit code.
  Future<Booking> start(String id, String code);

  /// Published sub-services of [serviceId] that may be added as extras.
  Future<List<SubService>> extrasFor(String serviceId);

  /// Proposes extra items, by sub-service ID and quantity, for approval.
  Future<Booking> proposeExtras(String id, Map<String, int> quantities);

  /// Completes the job, confirming the cash was received.
  Future<Booking> complete(String id);

  /// Rates the customer.
  Future<void> review(String id, CustomerReview review);
}
