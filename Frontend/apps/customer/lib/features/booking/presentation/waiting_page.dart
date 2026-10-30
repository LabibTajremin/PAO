import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking, BookingStatus, Timing;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/data/api_booking_repository.dart';
import 'package:pao_customer/features/booking/presentation/track_cubit.dart';
import 'package:pao_customer/features/booking/presentation/waiting_views.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Waiting for the provider to answer (C13), with the declined (C47) and
/// timed-out (C13b) exits back to the provider list.
class WaitingPage extends StatelessWidget {
  /// Creates the page.
  const WaitingPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TrackCubit(
      ApiBookingRepository(services.api),
      bookingId,
      now: services.now,
    )..load().ignore(),
    child: BlocConsumer<TrackCubit, TrackState>(
      listenWhen: (a, b) => _next(b.booking) != _next(a.booking),
      listener: (context, s) {
        final next = _next(s.booking);
        if (next != null) context.go(Routes.booking(bookingId, next));
      },
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.bookingWaitingTitle),
        body: ViewStateView<Booking>(
          state: s.view,
          onRetry: context.read<TrackCubit>().load,
          builder: (_, b) => _body(s, b),
        ),
      ),
    ),
  );

  Widget _body(TrackState s, Booking b) => switch (b.status) {
    BookingStatus.requested when !s.expired => WaitingView(state: s),
    BookingStatus.requested ||
    BookingStatus.timedOut ||
    BookingStatus.rejected => MissedView(booking: b),
    BookingStatus.cancelled => const CancelledView(),
    _ => const SizedBox.shrink(),
  };
}

const Set<BookingStatus> _answered = {
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
  BookingStatus.inProgress,
  BookingStatus.completed,
};

// Where an answered booking continues: a scheduled booking that was just
// accepted is confirmed for later (C48); anything further along is live.
String? _next(Booking? b) {
  if (b == null || !_answered.contains(b.status)) return null;
  return b.timing == Timing.scheduled && b.status == BookingStatus.accepted
      ? 'confirmed'
      : 'live';
}
