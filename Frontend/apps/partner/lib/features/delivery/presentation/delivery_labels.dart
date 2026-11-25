import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// The words for how an order repeats.
String patternLabel(PartnerL10n t, DeliveryPattern p) => switch (p) {
  DeliveryPattern.once => t.orderPatternOnce,
  DeliveryPattern.daily => t.orderPatternDaily,
  DeliveryPattern.weekdays => t.orderPatternWeekdays,
  DeliveryPattern.weekly => t.orderPatternWeekly,
  DeliveryPattern.monthly => t.orderPatternMonthly,
};

/// The words and colour of an order's status.
(String, PaoTone) subscriptionStatus(PartnerL10n t, SubscriptionStatus s) =>
    switch (s) {
      SubscriptionStatus.requested => (t.subRequested, PaoTone.warning),
      SubscriptionStatus.active => (t.subActive, PaoTone.accent),
      SubscriptionStatus.paused => (t.subPaused, PaoTone.neutral),
      SubscriptionStatus.finished => (t.subFinished, PaoTone.success),
      SubscriptionStatus.declined => (t.subDeclined, PaoTone.neutral),
      SubscriptionStatus.cancelled => (t.subCancelled, PaoTone.neutral),
    };

/// The words and colour of one delivery's status.
(String, PaoTone) deliveryStatus(PartnerL10n t, DeliveryStatus s) =>
    switch (s) {
      DeliveryStatus.scheduled => (t.deliveryScheduled, PaoTone.neutral),
      DeliveryStatus.preparing => (t.deliveryPreparing, PaoTone.warning),
      DeliveryStatus.outForDelivery => (t.deliveryOut, PaoTone.accent),
      DeliveryStatus.delivered => (t.deliveryDelivered, PaoTone.success),
      DeliveryStatus.skipped => (t.deliverySkipped, PaoTone.neutral),
      DeliveryStatus.declined => (t.deliveryDeclined, PaoTone.neutral),
      DeliveryStatus.cancelled => (t.deliveryCancelled, PaoTone.neutral),
    };
