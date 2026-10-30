import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/job/domain/job_repository.dart';

/// [JobRepository] on the PAO API.
class ApiJobRepository implements JobRepository {
  /// Creates the repository.
  ApiJobRepository(Dio api)
    : _jobs = ProviderJobsApi(api),
      _provider = ProviderApi(api);

  final ProviderJobsApi _jobs;
  final ProviderApi _provider;

  @override
  Future<Booking> job(String id) async =>
      (await _jobs.getProviderJob(bookingId: id)).data!;

  @override
  Future<Booking> onTheWay(String id) async =>
      (await _jobs.markOnTheWay(bookingId: id)).data!;

  @override
  Future<Booking> arrived(String id) async =>
      (await _jobs.markArrived(bookingId: id)).data!;

  @override
  Future<Booking> cancel(
    String id,
    ProviderCancelInputReasonEnum reason,
    String? note,
  ) async => (await _jobs.cancelProviderJob(
    bookingId: id,
    providerCancelInput: ProviderCancelInput(reason: reason, note: note),
  )).data!;

  @override
  Future<Booking> start(String id, String code) async => (await _jobs.startJob(
    bookingId: id,
    startCode: StartCode(code: code),
  )).data!;

  @override
  Future<List<SubService>> extrasFor(String serviceId) async {
    final tree = (await _provider.getProviderCatalog()).data!;
    return [
      for (final category in tree.categories)
        for (final service in category.services)
          if (service.id == serviceId)
            ...?service.subServices?.where((s) => s.published),
    ];
  }

  @override
  Future<Booking> proposeExtras(String id, Map<String, int> quantities) async =>
      (await _jobs.proposeExtras(
        bookingId: id,
        extrasInput: ExtrasInput(
          items: [
            for (final MapEntry(:key, :value) in quantities.entries)
              BookingItemInput(subServiceId: key, quantity: value),
          ],
        ),
      )).data!;

  @override
  Future<Booking> complete(String id) async => (await _jobs.completeJob(
    bookingId: id,
    completeInput: CompleteInput(cashReceived: true),
  )).data!;

  @override
  Future<void> review(String id, CustomerReview review) => _jobs.reviewCustomer(
    bookingId: id,
    reviewInput: ReviewInput(
      stars: review.stars,
      tags: review.tags,
      comment: review.comment.isEmpty ? null : review.comment,
    ),
  );
}
