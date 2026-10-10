import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';
import 'package:pao_customer/features/bookings/presentation/bill_rows.dart';
import 'package:pao_customer/features/bookings/presentation/booking_actions.dart';
import 'package:pao_customer/features/bookings/presentation/booking_sections.dart';
import 'package:pao_customer/features/bookings/presentation/status_labels.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The loaded content of C19 and C57.
class BookingDetailView extends StatelessWidget {
  /// Creates the view of [booking]; [launcher] calls the provider.
  const BookingDetailView({
    required this.booking,
    required this.launcher,
    super.key,
  });

  /// The booking.
  final Booking booking;

  /// The dialler.
  final Launcher launcher;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final provider = b.provider;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        _Header(booking: b),
        if (endedStatuses.contains(b.status)) ...[
          const SizedBox(height: PaoSpace.lg),
          EndedNote(booking: b),
        ],
        if (provider != null) ...[
          _Heading(context.t.bookingsProvider),
          BookingProviderCard(
            provider: provider,
            launcher: launcher,
            live: liveStatuses.contains(b.status),
          ),
        ],
        _Heading(context.t.bookingsAddress),
        Text([?b.address.line1, ?b.address.line2, b.address.area].join(', ')),
        if (b.note case final String note when note.isNotEmpty) ...[
          _Heading(context.t.bookingsNote),
          Text(note),
        ],
        ..._timelineAndBill(context, b),
        const SizedBox(height: PaoSpace.xl),
        BookingActions(booking: b),
      ],
    );
  }
}

List<Widget> _timelineAndBill(BuildContext context, Booking b) => [
  if (b.timeline.isNotEmpty) ...[
    _Heading(context.t.bookingsTimeline),
    PaoStatusStepper(
      steps: [
        for (final e in b.timeline)
          [
            bookingStatusLabel(context.t, e.status),
            context.when(e.at, 'd MMM, h:mm a'),
          ].join(' · '),
      ],
      current: b.timeline.length - 1,
    ),
  ],
  _Heading(context.t.bookingsBill),
  BillRows(items: b.items, total: b.total),
  Text(
    b.status == BookingStatus.completed
        ? context.t.bookingsPaidCash
        : context.t.bookingsPayCash,
    style: Theme.of(context).textTheme.bodySmall,
  ),
];

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PaoSpace.xl, bottom: PaoSpace.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.local(booking.serviceName),
                  style: text.titleLarge,
                ),
              ),
              PaoBadge(
                label: bookingStatusLabel(context.t, booking.status),
                tone: bookingStatusTone(booking.status),
              ),
            ],
          ),
          Text(booking.number, style: text.bodySmall),
          const SizedBox(height: PaoSpace.md),
          Text(context.when(booking.scheduledAt ?? booking.createdAt)),
        ],
      ),
    );
  }
}
