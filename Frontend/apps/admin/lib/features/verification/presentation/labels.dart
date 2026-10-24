import 'package:flutter/material.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Name of a verification item (PRD §6.2).
String itemLabel(AdminL10n t, ItemType type) => switch (type) {
  ItemType.nid => t.verifyItemNid,
  ItemType.selfie => t.verifyItemSelfie,
  ItemType.policeClearance => t.verifyItemPolice,
  ItemType.address => t.verifyItemAddress,
  ItemType.emergencyContact => t.verifyItemEmergency,
  ItemType.skillProof => t.verifyItemSkill,
  ItemType.serviceArea => t.verifyItemServiceArea,
  ItemType.codeOfConduct => t.verifyItemConduct,
};

/// Status of a verification item.
String statusLabel(AdminL10n t, ItemStatus status) => switch (status) {
  ItemStatus.missing => t.verifyStatusMissing,
  ItemStatus.pending => t.verifyStatusPending,
  ItemStatus.approved => t.verifyStatusApproved,
  ItemStatus.rejected => t.verifyStatusRejected,
  ItemStatus.expired => t.verifyStatusExpired,
};

/// Badge colour of an item status.
PaoTone statusTone(ItemStatus status) => switch (status) {
  ItemStatus.approved => PaoTone.success,
  ItemStatus.pending => PaoTone.accent,
  ItemStatus.rejected || ItemStatus.expired => PaoTone.danger,
  ItemStatus.missing => PaoTone.neutral,
};

/// A verification level with its name (PRD §6.1).
String levelLabel(AdminL10n t, int level) => switch (level) {
  0 => t.verifyLevel0,
  1 => t.verifyLevel1,
  _ => t.verifyLevel2,
};

/// What the face check found.
String faceLabel(AdminL10n t, VerificationReviewFaceMatchEnum? face) =>
    switch (face) {
      VerificationReviewFaceMatchEnum.match => t.verifyFaceMatch,
      VerificationReviewFaceMatchEnum.noMatch => t.verifyFaceNoMatch,
      VerificationReviewFaceMatchEnum.manualReview => t.verifyFaceManual,
      _ => t.verifyFaceNotRun,
    };

/// Icon colour of a face check.
Color faceColor(VerificationReviewFaceMatchEnum? face) => switch (face) {
  VerificationReviewFaceMatchEnum.match => PaoColors.success,
  VerificationReviewFaceMatchEnum.noMatch => PaoColors.danger,
  VerificationReviewFaceMatchEnum.manualReview => PaoColors.warning,
  _ => PaoColors.textTertiary,
};

/// Gender as written in the profile.
String genderLabel(AdminL10n t, Gender gender) => switch (gender) {
  Gender.female => t.verifyGenderFemale,
  Gender.male => t.verifyGenderMale,
  Gender.other => t.verifyGenderOther,
};

/// Name of an uploaded document, or its raw kind when unknown.
String documentLabel(AdminL10n t, String kind) => switch (kind) {
  'nid_front' => t.verifyDocNidFront,
  'nid_back' => t.verifyDocNidBack,
  'selfie' => t.verifyItemSelfie,
  'police_clearance' => t.verifyItemPolice,
  'skill_proof' => t.verifyItemSkill,
  _ => kind,
};

/// Label of a submitted value, or its raw key when unknown.
String fieldLabel(AdminL10n t, String key) => switch (key) {
  'issueDate' => t.verifyFieldIssueDate,
  'presentAddress' => t.verifyPresentAddress,
  'permanentAddress' => t.verifyPermanentAddress,
  'workingRadiusM' => t.verifyFieldRadius,
  'services' => t.verifyFieldServices,
  'homeLat' => t.verifyFieldHomeLat,
  'homeLng' => t.verifyFieldHomeLng,
  'name' => t.verifyFieldName,
  'relation' => t.verifyFieldRelation,
  'phone' => t.verifyPhone,
  _ => key,
};

/// Reasons verifiers give most often, offered when rejecting.
List<String> rejectTemplates(AdminL10n t) => [
  t.verifyReasonBlurry,
  t.verifyReasonName,
  t.verifyReasonExpired,
  t.verifyReasonFace,
  t.verifyReasonCropped,
];

/// How long a provider has waited, in hours or whole days.
String waitedLabel(AdminL10n t, int hours) =>
    hours < 48 ? t.verifyAgeHours(hours) : t.verifyAgeDays(hours ~/ 24);

/// Colour of the wait: amber after a day, red after two.
Color waitedColor(int hours) => hours >= 48
    ? PaoColors.danger
    : hours >= 24
    ? PaoColors.warning
    : PaoColors.textPrimary;
