import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/bookings/presentation/booking_timeline.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Status, timing, money, address and cancellation of a booking.
class BookingOverview extends StatelessWidget {
  /// Creates the section.
  const BookingOverview({required this.booking, super.key});

  /// The booking.
  final Booking booking;

  List<Widget> _facts(BuildContext context) {
    final t = context.t;
    final b = booking;
    final started = reached(b.timeline, BookingStatus.inProgress);
    final done = reached(b.timeline, BookingStatus.completed);
    final cancel = reached(b.timeline, BookingStatus.cancelled);
    final address = [?b.address.line1, ?b.address.line2, b.address.area];
    return [
      Fact(t.bookingsService, context.local(b.serviceName)),
      Fact(t.bookingsCreated, context.when(b.createdAt)),
      Fact(
        t.bookingsWhen,
        b.scheduledAt == null ? t.bookingsAsap : context.when(b.scheduledAt!),
      ),
      if (b.endsAt case final at?) Fact(t.bookingsEnds, context.when(at)),
      if (started != null) Fact(t.bookingsStarted, context.when(started.at)),
      if (done != null) Fact(t.bookingsFinished, context.when(done.at)),
      Fact(t.bookingsTotal, context.money(b.total)),
      Fact(
        t.bookingsPayment,
        (b.cashReceived ?? false) ? t.bookingsCashReceived : t.bookingsCash,
      ),
      Fact(t.bookingsAddress, address.join(', ')),
      if (b.note case final note?) Fact(t.bookingsNote, note),
      if (cancel != null)
        Fact(
          t.bookingsCancelledBy(actorLabel(t, cancel.actor)),
          cancel.reason ?? '–',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => Section(
    title: booking.number,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PaoSpace.lg,
      children: [
        PaoBadge(
          label: bookingStatusLabel(context.t, booking.status),
          tone: bookingStatusTone(booking.status),
        ),
        Wrap(
          spacing: PaoSpace.lg,
          runSpacing: PaoSpace.md,
          children: _facts(context),
        ),
      ],
    ),
  );
}

/// The customer and the provider, each linking to their admin record.
class BookingParties extends StatelessWidget {
  /// Creates the section.
  const BookingParties({
    required this.booking,
    required this.canOpenCustomer,
    required this.canOpenProvider,
    super.key,
  });

  /// The booking.
  final Booking booking;

  /// Whether the admin may open customers (A09).
  final bool canOpenCustomer;

  /// Whether the admin may open providers (A08).
  final bool canOpenProvider;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Section(
      title: t.bookingsParties,
      child: Column(
        children: [
          _Party(
            role: t.bookingsCustomer,
            party: booking.customer,
            list: Routes.customers,
            canOpen: canOpenCustomer,
          ),
          _Party(
            role: t.bookingsProvider,
            party: booking.provider,
            list: Routes.providers,
            canOpen: canOpenProvider,
          ),
        ],
      ),
    );
  }
}

class _Party extends StatelessWidget {
  const _Party({
    required this.role,
    required this.party,
    required this.list,
    required this.canOpen,
  });

  final String role;
  final BookingParty? party;
  final String list;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final p = party;
    if (p == null) {
      return PaoListRow(title: context.t.bookingsNotAssigned, subtitle: role);
    }
    return PaoListRow(
      leading: PaoAvatar(name: p.name, size: 40),
      title: p.name,
      subtitle: [role, ?p.phone].join(' · '),
      onTap: canOpen ? () => context.go(Routes.detail(list, p.id)) : null,
    );
  }
}
