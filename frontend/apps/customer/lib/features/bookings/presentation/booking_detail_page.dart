import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/bookings/data/api_bookings_repository.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_view.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One booking: timeline, bill, provider and what can be done next (C19,
/// cancelled C57).
class BookingDetailPage extends StatelessWidget {
  /// Creates the page for [bookingId].
  const BookingDetailPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The booking.
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final repo = ApiBookingsRepository(services.api);
    // Keyed so that opening another booking over this route reloads.
    return BlocProvider(
      key: ValueKey(bookingId),
      create: (_) =>
          LoadCubit<Booking>(() => repo.booking(bookingId)).loading(),
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.bookingsDetailTitle),
        body: BlocBuilder<LoadCubit<Booking>, ViewState<Booking>>(
          builder: (context, state) {
            final cubit = context.read<LoadCubit<Booking>>();
            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ViewStateView<Booking>(
                state: state,
                onRetry: cubit.load,
                builder: (_, booking) => BookingDetailView(
                  booking: booking,
                  launcher: services.launcher,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
