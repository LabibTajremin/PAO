import 'package:flutter/widgets.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// The customer-facing name of [badge] (PRD §6.1).
String badgeLabel(PartnerL10n t, Badge badge) => {
  Badge.none: t.profBadgeNone,
  Badge.verified: t.profBadgeVerified,
  Badge.verifiedPro: t.profBadgeVerifiedPro,
}[badge]!;

/// The colour of [badge].
PaoTone badgeTone(Badge badge) => switch (badge) {
  Badge.none => PaoTone.neutral,
  Badge.verified => PaoTone.success,
  Badge.verifiedPro => PaoTone.accent,
};

/// The name of verification [level] 0–2 (PRD §6.1).
String levelName(PartnerL10n t, int level) =>
    [t.profLevel0, t.profLevel1, t.profLevel2][level.clamp(0, 2)];

/// The name of a verification document.
String itemLabel(PartnerL10n t, ItemType type) => {
  ItemType.nid: t.profItemNid,
  ItemType.selfie: t.profItemSelfie,
  ItemType.policeClearance: t.profItemPoliceClearance,
  ItemType.address: t.profItemAddress,
  ItemType.emergencyContact: t.profItemEmergencyContact,
  ItemType.skillProof: t.profItemSkillProof,
  ItemType.serviceArea: t.profItemServiceArea,
  ItemType.codeOfConduct: t.profItemCodeOfConduct,
}[type]!;

/// The name of a document's review status.
String itemStatusLabel(PartnerL10n t, ItemStatus status) => {
  ItemStatus.missing: t.profStatusMissing,
  ItemStatus.pending: t.profStatusPending,
  ItemStatus.approved: t.profStatusApproved,
  ItemStatus.rejected: t.profStatusRejected,
  ItemStatus.expired: t.profStatusExpired,
}[status]!;

/// The colour of a document's review status.
PaoTone itemStatusTone(ItemStatus status) => switch (status) {
  ItemStatus.approved => PaoTone.success,
  ItemStatus.pending => PaoTone.warning,
  ItemStatus.missing => PaoTone.neutral,
  ItemStatus.rejected || ItemStatus.expired => PaoTone.danger,
};

/// The text of a review tag.
String tagLabel(PartnerL10n t, ReviewTag tag) => {
  ReviewTag.onTime: t.profTagOnTime,
  ReviewTag.professional: t.profTagProfessional,
  ReviewTag.qualityWork: t.profTagQualityWork,
  ReviewTag.clean: t.profTagClean,
  ReviewTag.friendly: t.profTagFriendly,
  ReviewTag.fairPrice: t.profTagFairPrice,
  ReviewTag.late_: t.profTagLate,
  ReviewTag.rude: t.profTagRude,
  ReviewTag.poorQuality: t.profTagPoorQuality,
  ReviewTag.messy: t.profTagMessy,
  ReviewTag.polite: t.profTagPolite,
  ReviewTag.clearInstructions: t.profTagClearInstructions,
  ReviewTag.paidPromptly: t.profTagPaidPromptly,
  ReviewTag.safePlace: t.profTagSafePlace,
  ReviewTag.unclearInstructions: t.profTagUnclearInstructions,
  ReviewTag.unsafePlace: t.profTagUnsafePlace,
}[tag]!;

/// The profile photo at [url], if there is one.
ImageProvider? photoOf(String? url) => url == null ? null : NetworkImage(url);
