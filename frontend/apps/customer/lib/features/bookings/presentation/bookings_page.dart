import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/bookings/data/api_bookings_repository.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';
import 'package:pao_customer/features/bookings/presentation/booking_card.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Upcoming and past bookings (C18, C18b) with their empty states (C58).
class BookingsPage extends StatefulWidget {
  /// Creates the page.
  const BookingsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late final BookingsRepository _repo = ApiBookingsRepository(
    widget.services.api,
  );
  BookingsTab _tab = BookingsTab.upcoming;

  Widget _list(BookingsTab tab) => BlocProvider(
    key: ValueKey(tab),
    create: (_) =>
        PagedCubit<BookingSummary>((cursor) => _repo.list(tab, cursor: cursor))
            .loading(),
    child: Builder(
      builder: (context) => RefreshIndicator(
        onRefresh: context.read<PagedCubit<BookingSummary>>().load,
        child: PagedView<BookingSummary>(
          itemBuilder: (_, booking) => BookingCard(booking: booking),
          empty: _Empty(tab: tab),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PaoAppBar(title: context.t.bookingsTitle),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PaoSpace.lg,
            PaoSpace.md,
            PaoSpace.lg,
            0,
          ),
          child: PaoSegmented<BookingsTab>(
            segments: {
              BookingsTab.upcoming: context.t.bookingsUpcoming,
              BookingsTab.past: context.t.bookingsPast,
            },
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
        ),
        Expanded(child: _list(_tab)),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.tab});

  final BookingsTab tab;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return tab == BookingsTab.upcoming
        ? PaoEmptyState(
            icon: Icons.event_available_outlined,
            title: t.bookingsEmptyUpcoming,
            message: t.bookingsEmptyUpcomingBody,
            action: PaoButton(
              label: t.bookingsBookService,
              expand: false,
              onPressed: () => context.go(Routes.home),
            ),
          )
        : PaoEmptyState(
            icon: Icons.history,
            title: t.bookingsEmptyPast,
            message: t.bookingsEmptyPastBody,
          );
  }
}
