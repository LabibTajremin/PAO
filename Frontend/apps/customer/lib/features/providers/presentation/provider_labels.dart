import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The customer-facing name of [badge] (PRD §6.1).
String badgeLabel(CustomerL10n t, Badge badge) => switch (badge) {
  Badge.none => t.provBadgeNone,
  Badge.verified => t.provBadgeVerified,
  Badge.verifiedPro => t.provBadgeVerifiedPro,
};

/// The colour of [badge].
PaoTone badgeTone(Badge badge) => switch (badge) {
  Badge.none => PaoTone.neutral,
  Badge.verified => PaoTone.success,
  Badge.verifiedPro => PaoTone.accent,
};

/// How far away a provider is, e.g. "800 m away" or "1.2 km away".
String distanceText(CustomerL10n t, int metres, String lang) {
  final locale = lang == 'bn' ? 'bn' : 'en';
  if (metres < 1000) return t.provMAway(formatCount(metres, locale: locale));
  return t.provKmAway(NumberFormat('0.0', locale).format(metres / 1000));
}

/// The text of a review tag.
String tagLabel(CustomerL10n t, ReviewTag tag) => {
  ReviewTag.onTime: t.provTagOnTime,
  ReviewTag.professional: t.provTagProfessional,
  ReviewTag.qualityWork: t.provTagQualityWork,
  ReviewTag.clean: t.provTagClean,
  ReviewTag.friendly: t.provTagFriendly,
  ReviewTag.fairPrice: t.provTagFairPrice,
  ReviewTag.late_: t.provTagLate,
  ReviewTag.rude: t.provTagRude,
  ReviewTag.poorQuality: t.provTagPoorQuality,
  ReviewTag.messy: t.provTagMessy,
  ReviewTag.polite: t.provTagPolite,
  ReviewTag.clearInstructions: t.provTagClearInstructions,
  ReviewTag.paidPromptly: t.provTagPaidPromptly,
  ReviewTag.safePlace: t.provTagSafePlace,
  ReviewTag.unclearInstructions: t.provTagUnclearInstructions,
  ReviewTag.unsafePlace: t.provTagUnsafePlace,
}[tag]!;

/// The photo at [url], if there is one.
ImageProvider? photoOf(String? url) => url == null ? null : NetworkImage(url);
