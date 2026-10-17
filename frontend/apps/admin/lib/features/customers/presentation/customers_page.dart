import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/customers/data/api_customers_repository.dart';
import 'package:pao_admin/features/customers/domain/customers_repository.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/filtered_paged_cubit.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/filter_menu.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

typedef _Cubit = FilteredPagedCubit<AdminCustomerSummary, CustomerFilter>;

/// Customers list with search and a status filter (A09).
class CustomersPage extends StatefulWidget {
  /// Creates the page.
  const CustomersPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late final _Cubit _cubit = _Cubit(
    const CustomerFilter(),
    ApiCustomersRepository(widget.services.api).list,
  ).loading();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  List<AdminColumn<AdminCustomerSummary>> _columns(AdminL10n t, bool wide) => [
    AdminColumn(t.peopleName, (c) => Text(c.name), flex: 3),
    if (wide) AdminColumn(t.peoplePhone, (c) => Text(c.phone ?? ''), flex: 2),
    AdminColumn(
      t.peopleFilterStatus,
      (c) => StatusCell(
        label: accountStatusLabel(t, c.status),
        tone: accountStatusTone(c.status),
      ),
      flex: 2,
    ),
    AdminColumn(t.customersBookings, (c) => Text(context.count(c.bookings))),
    AdminColumn(
      t.peopleRating,
      (c) => Text(c.rating == null ? '–' : context.rating(c.rating!)),
    ),
    if (wide)
      AdminColumn(
        t.peopleJoined,
        (c) => Text(context.when(c.createdAt, 'd MMM y')),
        flex: 2,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider<PagedCubit<AdminCustomerSummary>>.value(
      value: _cubit,
      child: LayoutBuilder(
        builder: (context, box) => PagedTable<AdminCustomerSummary>(
          header: [
            ListHeading(t.customersTitle),
            _Filters(cubit: _cubit),
          ],
          columns: _columns(t, box.maxWidth >= twoColumnWidth),
          empty: PaoEmptyState(title: t.customersEmpty),
          onOpen: (c) => context.go(Routes.detail(Routes.customers, c.id)),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.cubit});

  final _Cubit cubit;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<_Cubit, PagedState<AdminCustomerSummary>>(
        bloc: cubit,
        builder: (context, _) {
          final t = context.t;
          final f = cubit.filter;
          return FilterBar(
            searchHint: t.customersSearch,
            search: (q) => cubit.apply(f.searching(q)),
            filters: [
              FilterMenu<AccountStatus>(
                label: t.peopleFilterStatus,
                options: accountStatusOptions(t),
                value: f.status,
                onChanged: (s) => cubit.apply(f.withStatus(s)),
              ),
            ],
          );
        },
      );
}
