import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';
import 'package:pao_customer/features/bookings/presentation/status_labels.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_customer/shared/photos.dart';
import 'package:pao_ui/pao_ui.dart';

/// The provider of a booking, with a call button while the job is live.
class BookingProviderCard extends StatelessWidget {
  /// Creates the card.
  const BookingProviderCard({
    required this.provider,
    required this.launcher,
    this.live = false,
    super.key,
  });

  /// The provider.
  final BookingParty provider;

  /// The dialler.
  final Launcher launcher;

  /// Whether the job is under way, so calling makes sense.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final photo = provider.photoUrl;
    final rating = provider.rating;
    final phone = provider.phone;
    return PaoCard(
      padding: EdgeInsets.zero,
      child: PaoListRow(
        leading: PaoAvatar(name: provider.name, image: networkPhoto(photo)),
        title: provider.name,
        subtitle: rating == null
            ? null
            : context.t.bookingsRatingSummary(
                rating.toStringAsFixed(1),
                '${provider.ratingCount ?? 0}',
              ),
        trailing: phone == null || !live
            ? null
            : IconButton(
                tooltip: context.t.bookingsCallProvider,
                icon: const Icon(Icons.call_outlined),
                onPressed: () => launcher.call(phone),
              ),
      ),
    );
  }
}

/// Why a booking ended without the job (C57): who stopped it, the reason and
/// that nothing was charged.
class EndedNote extends StatelessWidget {
  /// Creates the note for [booking], whose status is one of [endedStatuses].
  const EndedNote({required this.booking, super.key});

  /// The ended booking.
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final last = booking.timeline.lastOrNull;
    final reason = last?.reason;
    final lines = [
      if (booking.status == BookingStatus.cancelled) ?_who(t, last?.actor),
      if (reason != null && reason.isNotEmpty)
        t.bookingsEndedReason(endedReasonLabel(t, reason)),
      t.bookingsNoCharge,
    ];
    return PaoCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title(t), style: Theme.of(context).textTheme.titleMedium),
          for (final line in lines) Text(line),
        ],
      ),
    );
  }

  String _title(CustomerL10n t) => switch (booking.status) {
    BookingStatus.rejected => t.bookingsRejectedTitle,
    BookingStatus.timedOut => t.bookingsTimedOutTitle,
    _ => t.bookingsCancelledTitle,
  };

  String? _who(CustomerL10n t, TimelineEntryActorEnum? actor) =>
      switch (actor) {
        TimelineEntryActorEnum.customer => t.bookingsCancelledByYou,
        TimelineEntryActorEnum.provider => t.bookingsCancelledByProvider,
        null => null,
        _ => t.bookingsCancelledByPao,
      };
}
