import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Permission to approve or reject verification items (A05, A06).
const reviewPermission = 'verification:review';

/// Permission to open verification documents; every view is audited.
const docsPermission = 'verification:docs:view';

/// Level 1 document review (PRD §6.2, A-03).
abstract interface class VerificationRepository {
  /// One page of providers waiting for review, oldest first; [itemType]
  /// keeps only providers with that item pending.
  Future<Paged<VerificationQueueItem>> queue({
    ItemType? itemType,
    String? cursor,
  });

  /// Everything needed to review [providerId].
  Future<VerificationReview> review(String providerId);

  /// Approves [type] of [providerId]; returns the review with the new level.
  Future<VerificationReview> approve(String providerId, ItemType type);

  /// Rejects [type] of [providerId] with a [reason] the provider sees.
  Future<VerificationReview> reject(
    String providerId,
    ItemType type,
    String reason,
  );

  /// A short-lived signed URL for the document [mediaId].
  Future<String> documentUrl(String mediaId);

  /// The oldest waiting provider other than [current], or null if none.
  Future<String?> next(String current);
}
