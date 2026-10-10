import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// What the customer can do next with a booking, by its status.
class BookingActions extends StatelessWidget {
  /// Creates the buttons for [booking].
  const BookingActions({required this.booking, super.key});

  /// The booking.
  final Booking booking;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final button in _buttons(context))
        Padding(
          padding: const EdgeInsets.only(bottom: PaoSpace.sm),
          child: button,
        ),
    ],
  );

  List<Widget> _buttons(BuildContext context) {
    final t = context.t;
    final b = booking;
    final status = b.status;
    void open(String part) => context.push(Routes.booking(b.id, part));
    final buttons = <Widget>[
      if (status == BookingStatus.requested)
        PaoButton(label: t.bookingsWaiting, onPressed: () => open('waiting')),
      if (liveStatuses.contains(status))
        PaoButton(label: t.bookingsTrack, onPressed: () => open('live')),
      if (status == BookingStatus.completed) ...[
        if (b.reviewedByMe != true)
          PaoButton(label: t.bookingsRate, onPressed: () => open('rate')),
        PaoButton(
          label: t.bookingsReceipt,
          variant: PaoButtonVariant.soft,
          onPressed: () => open('receipt'),
        ),
      ],
      if (endedStatuses.contains(status))
        PaoButton(
          label: t.bookingsBookAgain,
          onPressed: () => context.push(Routes.serviceOf(b.serviceId)),
        ),
      if (status != BookingStatus.requested)
        PaoButton(
          label: t.bookingsReport,
          variant: PaoButtonVariant.ghost,
          icon: Icons.flag_outlined,
          onPressed: () => open('report'),
        ),
    ];
    return buttons;
  }
}
