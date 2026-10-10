import 'package:pao_partner/features/enrolment/domain/enrolment.dart';

/// A checked item (PRD §6.2); [step] is where it is uploaded again.
enum ItemKind {
  /// NID front and back.
  nid(EnrolStep.nid),

  /// Live selfie.
  selfie(EnrolStep.selfie),

  /// Police clearance certificate.
  policeClearance(EnrolStep.policeClearance),

  /// Present and permanent address.
  address(EnrolStep.personal),

  /// Emergency contact.
  emergencyContact(EnrolStep.emergencyContact),

  /// Skill or trade proof.
  skillProof(EnrolStep.skillProof),

  /// Services and home base.
  serviceArea(EnrolStep.area),

  /// Code of conduct.
  codeOfConduct(EnrolStep.codeOfConduct);

  ItemKind(this.step);

  /// The wizard step that collects it.
  final EnrolStep step;
}

/// Review state of an item.
enum ItemState {
  /// Not sent yet.
  missing,

  /// With a verifier.
  pending,

  /// Accepted.
  approved,

  /// Refused with a reason.
  rejected,

  /// Past its validity, e.g. a year-old police clearance.
  expired,
}

/// The customer-facing badge.
enum TrustBadge {
  /// Level 0.
  none,

  /// Level 1.
  verified,

  /// Level 2.
  verifiedPro,
}

/// One row of M14.
class CheckItem {
  /// Creates the row.
  const CheckItem({
    required this.kind,
    required this.state,
    this.reason,
    this.expiresAt,
  });

  /// What was checked.
  final ItemKind kind;

  /// Where review stands.
  final ItemState state;

  /// Why it was rejected.
  final String? reason;

  /// When the document stops being valid.
  final DateTime? expiresAt;

  /// Whether the provider must upload it again.
  bool get needsUpload =>
      state == ItemState.rejected || state == ItemState.expired;
}

/// Level 2 skill check (PRD §6.3).
class SkillCheck {
  /// Creates the info.
  const SkillCheck({
    required this.eligible,
    this.sessionAt,
    this.place,
    this.retryAfter,
  });

  /// May book a skill check.
  final bool eligible;

  /// Scheduled session time.
  final DateTime? sessionAt;

  /// Where the session is held.
  final String? place;

  /// End of the cooling-off period after a failed check.
  final DateTime? retryAfter;
}

/// Everything M14 shows.
class VerificationSummary {
  /// Creates the summary.
  const VerificationSummary({
    required this.level,
    required this.badge,
    required this.items,
    required this.cleared,
    required this.submitted,
    this.nextStep,
    this.skillCheck,
  });

  /// Verification level 0–2.
  final int level;

  /// Badge customers see.
  final TrustBadge badge;

  /// Per-item status.
  final List<CheckItem> items;

  /// May receive bookings.
  final bool cleared;

  /// The enrolment was sent for review.
  final bool submitted;

  /// First enrolment step still to do.
  final EnrolStep? nextStep;

  /// Level 2 info, when the server sends it.
  final SkillCheck? skillCheck;
}

/// Verification status (P-03).
abstract interface class VerificationRepository {
  /// Loads the status with the enrolment progress.
  Future<VerificationSummary> load();
}
