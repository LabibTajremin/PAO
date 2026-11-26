import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/delivery/domain/delivery_repository.dart';
import 'package:pao_customer/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_customer/features/delivery/presentation/subscriptions_page.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The order's card, its next dates and the moves it allows.
class SubscriptionView extends StatelessWidget {
  /// Creates the view; [onAct] runs a change against the repository.
  const SubscriptionView({
    required this.subscription,
    required this.onAct,
    super.key,
  });

  /// The order.
  final Subscription subscription;

  /// Runs a change and reloads.
  final void Function(Future<void> Function(DeliveryRepository) act) onAct;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = subscription;
    void move(SubscriptionMove m) => onAct((r) => r.move(s.id, m));
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        SubscriptionCard(s),
        Text(t.orderUpcoming, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: PaoSpace.sm),
        for (final d in s.upcoming ?? const <DeliveryDate>[])
          _DateRow(
            date: d,
            onSkip: (skip) => onAct((r) => r.skip(s.id, d.date, skip: skip)),
          ),
        const SizedBox(height: PaoSpace.lg),
        if (s.status == SubscriptionStatus.active)
          PaoButton(
            label: t.orderPause,
            variant: PaoButtonVariant.soft,
            onPressed: () => move(SubscriptionMove.pause),
          ),
        if (s.status == SubscriptionStatus.paused)
          PaoButton(
            label: t.orderResume,
            onPressed: () => move(SubscriptionMove.resume),
          ),
        if (s.status
            case SubscriptionStatus.requested ||
                SubscriptionStatus.active ||
                SubscriptionStatus.paused)
          PaoButton(
            label: t.orderCancel,
            variant: PaoButtonVariant.ghost,
            onPressed: () => move(SubscriptionMove.cancel),
          ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onSkip});

  final DeliveryDate date;
  final ValueChanged<bool> onSkip;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final d = date;
    final (status, tone) = deliveryStatus(t, d.status);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final day = DateFormat.MMMEd(locale).format(DateTime.parse(d.date));
    final skipped = d.status == DeliveryStatus.skipped;
    final booking = d.bookingId;
    return PaoListRow(
      title: day,
      subtitle: status,
      onTap: booking == null
          ? null
          : () => context.push(Routes.booking(booking)),
      trailing: (d.changeable ?? false)
          ? TextButton(
              onPressed: () => onSkip(!skipped),
              child: Text(skipped ? t.orderUnskip : t.orderSkip),
            )
          : PaoBadge(label: status, tone: tone),
    );
  }
}
