import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/provider_card.dart';
import 'package:pao_customer/features/booking/presentation/track_cubit.dart';
import 'package:pao_customer/features/connectivity/presentation/stale_notice.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The request is open: countdown, provider, total and cancel (C13).
class WaitingView extends StatelessWidget {
  /// Creates the view; [state] holds a requested booking.
  const WaitingView({required this.state, super.key});

  /// The tracked booking.
  final TrackState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = state.booking!;
    final provider = b.provider;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        if (state.stale) const StaleNotice(),
        _Countdown(booking: b, left: state.left),
        const SizedBox(height: PaoSpace.lg),
        Text(
          t.bookingWaitingBody,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PaoColors.textSecondary),
        ),
        const SizedBox(height: PaoSpace.xl),
        if (provider != null) PartyCard.party(provider),
        const SizedBox(height: PaoSpace.md),
        PaoListRow(
          title: context.local(b.serviceName),
          subtitle: b.number,
          trailing: Text(formatMoney(b.total, locale: context.lang)),
        ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.bookingWaitingCancel,
          variant: PaoButtonVariant.outline,
          onPressed: () async {
            final cubit = context.read<TrackCubit>();
            await context.push(Routes.booking(b.id, 'cancel'));
            await cubit.refresh();
          },
        ),
        PaoButton(
          label: t.bookingBackHome,
          variant: PaoButtonVariant.ghost,
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.booking, required this.left});

  final Booking booking;
  final Duration? left;

  @override
  Widget build(BuildContext context) {
    final rest = left;
    final deadline = booking.acceptDeadline;
    final window = deadline?.difference(booking.createdAt).inSeconds ?? 0;
    final value = rest == null || window <= 0
        ? 1.0
        : (rest.inSeconds / window).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox.square(
          dimension: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(value: value, strokeWidth: 8),
              Center(
                child: Text(
                  rest == null ? '' : clock(context, rest),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PaoSpace.lg),
        Text(
          context.t.bookingWaitingHeading(booking.provider?.name ?? ''),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

/// [d] as `m:ss` in the current language's digits.
String clock(BuildContext context, Duration d) {
  final seconds = NumberFormat('00', context.lang).format(d.inSeconds % 60);
  return '${context.count(d.inMinutes)}:$seconds';
}

/// The provider declined (C47) or did not answer in time (C13b).
class MissedView extends StatelessWidget {
  /// Creates the view; a requested booking here has run out of time locally.
  const MissedView({required this.booking, super.key});

  /// The booking that was not accepted.
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final declined = booking.status == BookingStatus.rejected;
    return PaoMessageState(
      icon: declined ? Icons.person_off_outlined : Icons.timer_off_outlined,
      title: declined
          ? t.bookingWaitingDeclinedTitle(booking.provider?.name ?? '')
          : t.bookingWaitingTimedOutTitle,
      message: t.bookingWaitingMissedBody,
      action: Column(
        children: [
          PaoButton(
            label: t.bookingWaitingChooseAnother,
            onPressed: () => context.go(providersAgain(booking)),
          ),
          PaoButton(
            label: t.bookingBackHome,
            variant: PaoButtonVariant.ghost,
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
    );
  }
}

/// The provider list for the same service and items, without the provider;
/// a duration hire keeps its start (C44).
String providersAgain(Booking b) {
  final hire = b.serviceModel == ServiceModel.durationHire;
  final draft = BookingDraft(
    serviceId: b.serviceId,
    items: {
      for (final item in b.items)
        if (!item.extra) item.subServiceId: item.quantity,
    },
    scheduledAt: hire ? b.scheduledAt?.toUtc().toIso8601String() : null,
  );
  return Uri(
    path: Routes.providersOf(b.serviceId),
    queryParameters: draft.toQuery(),
  ).toString();
}

/// The booking was cancelled (C53 seen from another screen).
class CancelledView extends StatelessWidget {
  /// Creates the view.
  const CancelledView({super.key});

  @override
  Widget build(BuildContext context) => PaoMessageState(
    icon: Icons.event_busy_outlined,
    title: context.t.cancelDoneTitle,
    action: PaoButton(
      label: context.t.bookingBackHome,
      expand: false,
      onPressed: () => context.go(Routes.home),
    ),
  );
}
