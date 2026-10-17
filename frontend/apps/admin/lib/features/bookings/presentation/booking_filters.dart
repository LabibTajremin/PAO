import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/bookings/domain/bookings_repository.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/filtered_paged_cubit.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/filter_menu.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The monitor's cubit.
typedef BookingsCubit = FilteredPagedCubit<BookingSummary, BookingFilter>;

/// Area search, status and creation-date filters of the bookings monitor.
class BookingFilters extends StatelessWidget {
  /// Creates the filters; [today] bounds the date picker.
  const BookingFilters({required this.cubit, required this.today, super.key});

  /// The monitor's rows.
  final BookingsCubit cubit;

  /// Today in Asia/Dhaka.
  final DateTime today;

  Future<void> _pickDates(BuildContext context) async {
    final f = cubit.filter;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      initialEntryMode: DatePickerEntryMode.input,
      initialDateRange: f.from == null
          ? null
          : DateTimeRange(
              start: DateTime.parse(f.from!),
              end: DateTime.parse(f.to!),
            ),
    );
    if (range == null) return;
    await cubit.apply(f.between(apiDate(range.start), apiDate(range.end)));
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BookingsCubit, PagedState<BookingSummary>>(
        bloc: cubit,
        builder: (context, _) {
          final t = context.t;
          final f = cubit.filter;
          return FilterBar(
            searchHint: t.bookingsAreaHint,
            search: (area) => cubit.apply(f.inArea(area)),
            filters: [
              FilterMenu<BookingStatus>(
                label: t.peopleFilterStatus,
                options: bookingStatusOptions(t),
                value: f.status,
                onChanged: (s) => cubit.apply(f.withStatus(s)),
              ),
              PaoChip(
                label: f.from == null
                    ? t.bookingsAnyDate
                    : '${context.day(f.from!)} – ${context.day(f.to!)}',
                selected: f.from != null,
                onTap: () => _pickDates(context),
              ),
              if (f.from != null)
                IconButton(
                  tooltip: t.bookingsClearDates,
                  icon: const Icon(Icons.close),
                  onPressed: () => cubit.apply(f.between(null, null)),
                ),
            ],
          );
        },
      );
}

/// Today's date in Asia/Dhaka for [now].
DateTime dhakaToday(DateTime now) {
  final local = now.toUtc().add(dhakaOffset);
  return DateTime(local.year, local.month, local.day);
}
