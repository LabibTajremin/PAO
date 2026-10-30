import 'package:dio/dio.dart';
import 'package:pao_admin/features/verification/domain/verification_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [VerificationRepository] on the PAO API.
class ApiVerificationRepository implements VerificationRepository {
  /// Creates the repository.
  ApiVerificationRepository(Dio api) : _api = AdminVerificationApi(api);

  final AdminVerificationApi _api;

  @override
  Future<Paged<VerificationQueueItem>> queue({
    ItemType? itemType,
    String? cursor,
  }) async {
    final res = await _api.listVerificationQueue(
      itemType: itemType?.value,
      cursor: cursor,
    );
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<VerificationReview> review(String providerId) async =>
      (await _api.getVerificationReview(providerId: providerId)).data!;

  @override
  Future<VerificationReview> approve(String providerId, ItemType type) async =>
      (await _api.approveVerificationItem(
        providerId: providerId,
        itemType: type.value,
      )).data!;

  @override
  Future<VerificationReview> reject(
    String providerId,
    ItemType type,
    String reason,
  ) async => (await _api.rejectVerificationItem(
    providerId: providerId,
    itemType: type.value,
    statusReason: StatusReason(reason: reason),
  )).data!;

  @override
  Future<String> documentUrl(String mediaId) async =>
      (await _api.getDocumentViewURL(mediaId: mediaId)).data!.url;

  @override
  Future<String?> next(String current) async {
    // The current provider may still head the queue while items remain, so
    // a second row is enough to find someone else.
    final res = await _api.listVerificationQueue(limit: 2);
    final others = res.data!.items.where((i) => i.providerId != current);
    return others.isEmpty ? null : others.first.providerId;
  }
}
