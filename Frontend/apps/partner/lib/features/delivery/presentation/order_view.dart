import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The order's summary, its answer buttons and its next dates.
class OrderView extends StatelessWidget {
  /// Creates the view.
  const OrderView({
    required this.subscription,
    required this.onAccept,
    required this.onDecline,
    required this.onDeclineDate,
    super.key,
  });

  /// The order.
  final Subscription subscription;

  /// Accepts a new order.
  final VoidCallback onAccept;

  /// Declines a new order.
  final VoidCallback onDecline;

  /// Declines one date.
  final ValueChanged<String> onDeclineDate;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = subscription;
    final (status, tone) = subscriptionStatus(t, s.status);
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        PaoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.local(s.serviceName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${patternLabel(t, s.pattern)} · '
                '${s.window.start}–${s.window.end}',
              ),
              Text(
                [
                  s.customer?.name,
                  s.address.area,
                  s.address.line1,
                ].whereType<String>().join(' · '),
              ),
              Row(
                children: [
                  Expanded(child: Text(t.orderPerDelivery)),
                  PaoMoneyText(s.total),
                ],
              ),
              const SizedBox(height: PaoSpace.sm),
              PaoBadge(label: status, tone: tone),
            ],
          ),
        ),
        if (s.status == SubscriptionStatus.requested) ...[
          const SizedBox(height: PaoSpace.lg),
          PaoButton(label: t.orderAccept, onPressed: onAccept),
          const SizedBox(height: PaoSpace.sm),
          PaoButton(
            label: t.orderDecline,
            variant: PaoButtonVariant.ghost,
            onPressed: onDecline,
          ),
        ],
        const SizedBox(height: PaoSpace.lg),
        Text(t.orderUpcoming, style: Theme.of(context).textTheme.titleSmall),
        for (final d in s.upcoming ?? const <DeliveryDate>[])
          PaoListRow(
            title: context.day(d.date, 'EEE, d MMM'),
            subtitle: deliveryStatus(t, d.status).$1,
            trailing:
                (d.changeable ?? false) && d.status == DeliveryStatus.scheduled
                ? TextButton(
                    onPressed: () => onDeclineDate(d.date),
                    child: Text(t.orderDeclineDate),
                  )
                : null,
          ),
      ],
    );
  }
}
