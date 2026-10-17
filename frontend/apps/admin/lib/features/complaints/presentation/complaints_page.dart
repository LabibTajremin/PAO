import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/complaints/data/api_complaints_repository.dart';
import 'package:pao_admin/features/complaints/domain/complaints_repository.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_labels.dart';
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

typedef _Cubit = FilteredPagedCubit<Complaint, ComplaintFilter>;

/// The complaints queue, filtered by status or "assigned to me" (A11).
class ComplaintsPage extends StatefulWidget {
  /// Creates the page.
  const ComplaintsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late final _Cubit _cubit = _Cubit(
    const ComplaintFilter(),
    ApiComplaintsRepository(widget.services.api).list,
  ).loading();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  List<AdminColumn<Complaint>> _columns(AdminL10n t, bool wide) => [
    AdminColumn(t.complaintsTicket, (c) => Text(c.ticketNumber), flex: 2),
    AdminColumn(
      t.complaintsReason,
      (c) => Text(complaintReasonLabel(t, c.reason)),
      flex: 2,
    ),
    if (wide)
      AdminColumn(
        t.complaintsReporter,
        (c) => Text(reporterLabel(t, c.reporterRole)),
      ),
    AdminColumn(
      t.peopleFilterStatus,
      (c) => StatusCell(
        label: complaintStatusLabel(t, c.status),
        tone: complaintStatusTone(c.status),
      ),
      flex: 2,
    ),
    AdminColumn(
      t.complaintsOpened,
      (c) => Text(context.when(c.createdAt, 'd MMM, h:mm a')),
      flex: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider<PagedCubit<Complaint>>.value(
      value: _cubit,
      child: LayoutBuilder(
        builder: (context, box) => PagedTable<Complaint>(
          header: [
            ListHeading(t.complaintsTitle),
            _Filters(cubit: _cubit),
          ],
          columns: _columns(t, box.maxWidth >= twoColumnWidth),
          empty: PaoEmptyState(title: t.complaintsEmpty),
          onOpen: (c) => context.go(Routes.detail(Routes.complaints, c.id)),
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
      BlocBuilder<_Cubit, PagedState<Complaint>>(
        bloc: cubit,
        builder: (context, _) {
          final t = context.t;
          final f = cubit.filter;
          return FilterBar(
            filters: [
              FilterMenu<ComplaintStatus>(
                label: t.peopleFilterStatus,
                options: complaintStatusOptions(t),
                value: f.status,
                onChanged: (s) => cubit.apply(f.withStatus(s)),
              ),
              PaoChip(
                label: t.complaintsMine,
                selected: f.mine,
                onTap: () => cubit.apply(f.toggleMine()),
              ),
            ],
          );
        },
      );
}
