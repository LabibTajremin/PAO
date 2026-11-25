import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// The words for how an order repeats.
String patternLabel(CustomerL10n t, DeliveryPattern p) => switch (p) {
  DeliveryPattern.once => t.orderPatternOnce,
  DeliveryPattern.daily => t.orderPatternDaily,
  DeliveryPattern.weekdays => t.orderPatternWeekdays,
  DeliveryPattern.weekly => t.orderPatternWeekly,
  DeliveryPattern.monthly => t.orderPatternMonthly,
};

/// The short name of day [d] (0 Sunday to 6 Saturday) in [locale].
String weekdayLabel(String locale, int d) =>
    // 2026-11-29 is a Sunday.
    DateFormat.E(locale).format(DateTime(2026, 11, 29 + d));

/// The words and colour of an order's status.
(String, PaoTone) subscriptionStatus(CustomerL10n t, SubscriptionStatus s) =>
    switch (s) {
      SubscriptionStatus.requested => (t.subRequested, PaoTone.warning),
      SubscriptionStatus.active => (t.subActive, PaoTone.accent),
      SubscriptionStatus.paused => (t.subPaused, PaoTone.neutral),
      SubscriptionStatus.finished => (t.subFinished, PaoTone.success),
      SubscriptionStatus.declined => (t.subDeclined, PaoTone.neutral),
      SubscriptionStatus.cancelled => (t.subCancelled, PaoTone.neutral),
    };

/// The words and colour of one delivery's status.
(String, PaoTone) deliveryStatus(CustomerL10n t, DeliveryStatus s) =>
    switch (s) {
      DeliveryStatus.scheduled => (t.deliveryScheduled, PaoTone.neutral),
      DeliveryStatus.preparing => (t.deliveryPreparing, PaoTone.accent),
      DeliveryStatus.outForDelivery => (t.deliveryOut, PaoTone.accent),
      DeliveryStatus.delivered => (t.deliveryDelivered, PaoTone.success),
      DeliveryStatus.skipped => (t.deliverySkipped, PaoTone.warning),
      DeliveryStatus.declined => (t.deliveryDeclined, PaoTone.danger),
      DeliveryStatus.cancelled => (t.deliveryCancelled, PaoTone.neutral),
    };
