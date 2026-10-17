import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/enrolment/data/api_enrolment_repository.dart'
    show progressOf;
import 'package:pao_partner/features/verification/domain/verification.dart';

/// [VerificationRepository] on the PAO API.
class ApiVerificationRepository implements VerificationRepository {
  /// Creates the repository.
  ApiVerificationRepository(Dio dio) : _api = ProviderEnrolmentApi(dio);

  final ProviderEnrolmentApi _api;

  @override
  Future<VerificationSummary> load() async {
    final v = (await _api.getVerificationStatus()).data!;
    final progress = progressOf((await _api.getEnrolment()).data!);
    return VerificationSummary(
      level: v.level,
      badge: TrustBadge.values.byName(v.badge.name),
      cleared: v.canReceiveBookings,
      submitted: progress.submitted,
      nextStep: progress.firstIncomplete,
      items: [
        for (final item in v.items)
          CheckItem(
            kind: ItemKind.values.byName(item.type.name),
            state: ItemState.values.byName(item.status.name),
            reason: item.rejectionReason,
            expiresAt: item.expiresAt,
          ),
      ],
      skillCheck: switch (v.level2) {
        final l2? => SkillCheck(
          eligible: l2.eligible,
          sessionAt: l2.nextSession?.scheduledAt,
          place: l2.nextSession?.location,
          retryAfter: l2.retryAfter,
        ),
        null => null,
      },
    );
  }
}
