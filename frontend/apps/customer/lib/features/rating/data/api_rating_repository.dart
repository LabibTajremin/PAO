import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/rating/domain/rating_repository.dart';

/// [RatingRepository] on the PAO API.
class ApiRatingRepository implements RatingRepository {
  /// Creates the repository.
  ApiRatingRepository(Dio api) : _api = CustomerBookingsApi(api);

  final CustomerBookingsApi _api;

  @override
  Future<Booking> booking(String id) async =>
      (await _api.getCustomerBooking(bookingId: id)).data!;

  @override
  Future<void> review(String id, ProviderReview review) => _api.reviewProvider(
    bookingId: id,
    reviewInput: ReviewInput(
      stars: review.stars,
      tags: review.tags.isEmpty ? null : review.tags,
      comment: review.comment.isEmpty ? null : review.comment,
    ),
  );
}
