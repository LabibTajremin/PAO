import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/bookings/data/api_bookings_repository.dart';
import 'package:pao_admin/features/bookings/presentation/booking_items.dart';
import 'package:pao_admin/features/bookings/presentation/booking_sections.dart';
import 'package:pao_admin/features/bookings/presentation/booking_timeline.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// One booking with both parties, items, extras and the full timeline
/// (A10). Read-only: the monitor watches, it does not steer bookings.
class BookingDetailPage extends StatelessWidget {
  /// Creates the page for booking [id].
  const BookingDetailPage({
    required this.services,
    required this.id,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The booking's ID.
  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = ApiBookingsRepository(services.api);
    final permissions = services.permissions;
    return BlocProvider(
      create: (_) => LoadCubit<Booking>(() => repo.detail(id)).loading(),
      child: BlocBuilder<LoadCubit<Booking>, ViewState<Booking>>(
        builder: (context, state) => DetailFrame<Booking>(
          back: BackLink(label: context.t.bookingsAll, to: Routes.bookings),
          state: state,
          onRetry: context.read<LoadCubit<Booking>>().load,
          builder: (context, b) => SplitColumns(
            first: [
              BookingOverview(booking: b),
              BookingItems(booking: b),
              if (b.pendingExtras case final extras?)
                ExtrasSection(extras: extras),
            ],
            second: [
              BookingParties(
                booking: b,
                canOpenCustomer: permissions.canSee('A09'),
                canOpenProvider: permissions.canSee('A08'),
              ),
              BookingTimeline(entries: b.timeline),
            ],
          ),
        ),
      ),
    );
  }
}
