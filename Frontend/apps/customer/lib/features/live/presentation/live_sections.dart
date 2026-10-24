import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart' show Booking, BookingStatus;
import 'package:pao_customer/features/live/presentation/start_code_card.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

const List<BookingStatus> _steps = [
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
  BookingStatus.inProgress,
  BookingStatus.completed,
];

/// Progress from accepted to completed (C-08).
class LiveStepper extends StatelessWidget {
  /// Creates the stepper at [status].
  const LiveStepper({required this.status, super.key});

  /// The booking's status.
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PaoCard(
      child: PaoStatusStepper(
        steps: [
          t.liveStepAccepted,
          t.liveStepOnTheWay,
          t.liveStepArrived,
          t.liveStepInProgress,
          t.liveStepCompleted,
        ],
        current: _steps.indexOf(status),
      ),
    );
  }
}

/// What is happening now and what the customer should do.
class LiveHeadline extends StatelessWidget {
  /// Creates the headline.
  const LiveHeadline({required this.booking, super.key});

  /// The booking.
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final name = booking.provider?.name ?? '';
    final at = booking.scheduledAt;
    final (title, hint) = switch (booking.status) {
      BookingStatus.accepted => (t.liveAcceptedTitle(name), t.liveAcceptedHint),
      BookingStatus.onTheWay => (t.liveOnTheWayTitle(name), t.liveCodeHint),
      BookingStatus.arrived => (t.liveArrivedTitle(name), t.liveArrivedHint),
      _ => (t.liveInProgressTitle, t.liveInProgressHint),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (at != null) Text(t.liveScheduledFor(context.when(at))),
        const SizedBox(height: PaoSpace.xs),
        Text(hint, style: const TextStyle(color: PaoColors.textSecondary)),
      ],
    );
  }
}

/// New extras wait for the customer's approval (C15).
class ExtrasNotice extends StatelessWidget {
  /// Creates the notice.
  const ExtrasNotice({
    required this.booking,
    required this.onReview,
    super.key,
  });

  /// The booking with a pending proposal.
  final Booking booking;

  /// Opens the approval screen.
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final added = booking.pendingExtras!.addedTotal;
    return PaoCard(
      highlighted: true,
      child: PaoListRow(
        leading: const Icon(Icons.playlist_add_check),
        title: context.t.liveExtrasNoticeTitle,
        subtitle: context.t.liveExtrasNoticeBody(
          formatMoney(added, locale: context.lang),
        ),
        trailing: Text(context.t.liveExtrasNoticeReview),
        onTap: onReview,
      ),
    );
  }
}

/// The service address, exact once accepted.
class AddressRow extends StatelessWidget {
  /// Creates the row.
  const AddressRow({required this.booking, super.key});

  /// The booking.
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final a = booking.address;
    final street = [a.line1, a.line2].nonNulls.where((s) => s.isNotEmpty);
    return PaoListRow(
      leading: const Icon(Icons.place_outlined),
      title: street.isEmpty ? a.area : street.join(', '),
      subtitle: street.isEmpty ? null : a.area,
    );
  }
}

/// The booking could not be loaded, but the start code is on the phone, so
/// the job can still start at the door (C36).
class OfflineCodeView extends StatelessWidget {
  /// Creates the view.
  const OfflineCodeView({required this.onRetry, super.key});

  /// Loads the booking again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(PaoSpace.lg),
    children: [
      PaoBanner(message: context.t.connectivityCodeSaved),
      const SizedBox(height: PaoSpace.lg),
      const StartCodeCard(),
      const SizedBox(height: PaoSpace.lg),
      PaoButton(
        label: context.common.actionRetry,
        variant: PaoButtonVariant.outline,
        onPressed: onRetry,
      ),
    ],
  );
}
