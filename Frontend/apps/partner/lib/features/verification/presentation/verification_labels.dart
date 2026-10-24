import 'package:pao_partner/features/verification/domain/verification.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// The name of [kind].
String itemLabel(PartnerL10n t, ItemKind kind) => switch (kind) {
  ItemKind.nid => t.verifItemNid,
  ItemKind.selfie => t.verifItemSelfie,
  ItemKind.policeClearance => t.verifItemPolice,
  ItemKind.address => t.verifItemAddress,
  ItemKind.emergencyContact => t.verifItemContact,
  ItemKind.skillProof => t.verifItemSkill,
  ItemKind.serviceArea => t.verifItemArea,
  ItemKind.codeOfConduct => t.verifItemConduct,
};

/// The badge for [state].
PaoBadge stateBadge(PartnerL10n t, ItemState state) => switch (state) {
  ItemState.missing => PaoBadge(label: t.verifStatusMissing),
  ItemState.pending => PaoBadge(
    label: t.verifStatusPending,
    tone: PaoTone.accent,
  ),
  ItemState.approved => PaoBadge(
    label: t.verifStatusApproved,
    tone: PaoTone.success,
  ),
  ItemState.rejected => PaoBadge(
    label: t.verifStatusRejected,
    tone: PaoTone.danger,
  ),
  ItemState.expired => PaoBadge(
    label: t.verifStatusExpired,
    tone: PaoTone.warning,
  ),
};

/// The name of [badge].
String badgeLabel(PartnerL10n t, TrustBadge badge) => switch (badge) {
  TrustBadge.none => t.verifBadgeNone,
  TrustBadge.verified => t.verifBadgeVerified,
  TrustBadge.verifiedPro => t.verifBadgePro,
};

/// What the provider should know about where review stands.
String statusMessage(PartnerL10n t, VerificationSummary s) {
  if (s.cleared) return t.verifCleared;
  if (!s.submitted) return t.verifIncomplete;
  if (s.items.any((i) => i.needsUpload)) return t.verifAttention;
  return t.verifPending;
}
