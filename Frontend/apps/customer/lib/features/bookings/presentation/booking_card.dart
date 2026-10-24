import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/bookings/presentation/status_labels.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One booking in the C18 lists: service, provider, date, status and total.
class BookingCard extends StatelessWidget {
  /// Creates the card.
  const BookingCard({required this.booking, super.key});

  /// The booking.
  final BookingSummary booking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final provider = booking.counterpartName;
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        onTap: () => context.push(Routes.booking(booking.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.local(booking.serviceName),
                    style: text.titleMedium,
                  ),
                ),
                PaoBadge(
                  label: bookingStatusLabel(context.t, booking.status),
                  tone: bookingStatusTone(booking.status),
                ),
              ],
            ),
            if (provider != null) Text(provider, style: text.bodyMedium),
            const SizedBox(height: PaoSpace.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.when(booking.scheduledAt ?? booking.createdAt),
                    style: text.bodySmall,
                  ),
                ),
                PaoMoneyText(booking.total, style: text.titleSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
