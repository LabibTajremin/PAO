import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/bookings/data/api_bookings_repository.dart';
import 'package:pao_admin/features/bookings/domain/bookings_repository.dart';
import 'package:pao_admin/features/bookings/presentation/booking_filters.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// How often the monitor reloads while it is open.
const bookingsRefreshEvery = Duration(seconds: 30);

/// Bookings monitor with filters; it reloads every [refreshEvery] while it
/// is open so operators see bookings move (A10).
class BookingsPage extends StatefulWidget {
  /// Creates the page.
  const BookingsPage({
    required this.services,
    this.refreshEvery = bookingsRefreshEvery,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Time between reloads.
  final Duration refreshEvery;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late final BookingsCubit _cubit = BookingsCubit(
    const BookingFilter(),
    ApiBookingsRepository(widget.services.api).list,
  ).loading();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      widget.refreshEvery,
      (_) => unawaited(_cubit.refresh()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    unawaited(_cubit.close());
    super.dispose();
  }

  List<AdminColumn<BookingSummary>> _columns(AdminL10n t, bool wide) => [
    AdminColumn(t.bookingsNumber, (b) => Text(b.number), flex: 2),
    AdminColumn(
      t.bookingsService,
      (b) => Text(context.local(b.serviceName)),
      flex: 2,
    ),
    AdminColumn(
      t.peopleFilterStatus,
      (b) => StatusCell(
        label: bookingStatusLabel(t, b.status),
        tone: bookingStatusTone(b.status),
      ),
      flex: 2,
    ),
    AdminColumn(t.bookingsTotal, (b) => PaoMoneyText(b.total)),
    if (wide)
      AdminColumn(
        t.bookingsCreated,
        (b) => Text(context.when(b.createdAt, 'd MMM, h:mm a')),
        flex: 2,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider<PagedCubit<BookingSummary>>.value(
      value: _cubit,
      child: LayoutBuilder(
        builder: (context, box) => PagedTable<BookingSummary>(
          header: [
            ListHeading(
              t.bookingsTitle,
              trailing: Text(
                t.bookingsAutoRefresh(
                  context.count(widget.refreshEvery.inSeconds),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            BookingFilters(
              cubit: _cubit,
              today: dhakaToday(widget.services.now()),
            ),
          ],
          columns: _columns(t, box.maxWidth >= twoColumnWidth),
          empty: PaoEmptyState(title: t.bookingsEmpty),
          onOpen: (b) => context.go(Routes.detail(Routes.bookings, b.id)),
        ),
      ),
    );
  }
}
