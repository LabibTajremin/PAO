import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Verification levels (PRD §6.1).
const providerLevels = [0, 1, 2];

/// The name of verification [level].
String levelLabel(AdminL10n t, int level) => switch (level) {
  0 => t.providersLevel0,
  1 => t.providersLevel1,
  _ => t.providersLevel2,
};

/// The name of a verification item [type].
String itemTypeLabel(AdminL10n t, ItemType type) => switch (type) {
  ItemType.nid => t.providersItemNid,
  ItemType.selfie => t.providersItemSelfie,
  ItemType.policeClearance => t.providersItemPoliceClearance,
  ItemType.address => t.providersItemAddress,
  ItemType.emergencyContact => t.providersItemEmergencyContact,
  ItemType.skillProof => t.providersItemSkillProof,
  ItemType.serviceArea => t.providersItemServiceArea,
  ItemType.codeOfConduct => t.providersItemCodeOfConduct,
};

/// The name of a verification item [status].
String itemStatusLabel(AdminL10n t, ItemStatus status) => switch (status) {
  ItemStatus.missing => t.providersItemMissing,
  ItemStatus.pending => t.providersItemPending,
  ItemStatus.approved => t.providersItemApproved,
  ItemStatus.rejected => t.providersItemRejected,
  ItemStatus.expired => t.providersItemExpired,
};

/// The badge colour of a verification item [status].
PaoTone itemStatusTone(ItemStatus status) => switch (status) {
  ItemStatus.approved => PaoTone.success,
  ItemStatus.pending => PaoTone.warning,
  ItemStatus.missing => PaoTone.neutral,
  ItemStatus.rejected || ItemStatus.expired => PaoTone.danger,
};

/// The provider's gender.
String genderLabel(AdminL10n t, Gender gender) => switch (gender) {
  Gender.female => t.providersGenderFemale,
  Gender.male => t.providersGenderMale,
  Gender.other => t.providersGenderOther,
};
