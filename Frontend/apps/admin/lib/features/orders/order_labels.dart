import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The words and colour of an order's status.
(String, PaoTone) subscriptionStatus(AdminL10n t, SubscriptionStatus s) =>
    switch (s) {
      SubscriptionStatus.requested => (t.subRequested, PaoTone.warning),
      SubscriptionStatus.active => (t.subActive, PaoTone.accent),
      SubscriptionStatus.paused => (t.subPaused, PaoTone.neutral),
      SubscriptionStatus.finished => (t.subFinished, PaoTone.success),
      SubscriptionStatus.declined => (t.subDeclined, PaoTone.neutral),
      SubscriptionStatus.cancelled => (t.subCancelled, PaoTone.neutral),
    };

/// The words for one delivery's status.
String deliveryStatus(AdminL10n t, DeliveryStatus s) => switch (s) {
  DeliveryStatus.scheduled => t.deliveryScheduled,
  DeliveryStatus.preparing => t.deliveryPreparing,
  DeliveryStatus.outForDelivery => t.deliveryOut,
  DeliveryStatus.delivered => t.deliveryDelivered,
  DeliveryStatus.skipped => t.deliverySkipped,
  DeliveryStatus.declined => t.deliveryDeclined,
  DeliveryStatus.cancelled => t.deliveryCancelled,
};
