import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/providers/data/api_providers_repository.dart';
import 'package:pao_admin/features/providers/domain/providers_repository.dart';
import 'package:pao_admin/features/providers/presentation/provider_labels.dart';
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

typedef _Cubit = FilteredPagedCubit<AdminProviderSummary, ProviderFilter>;

/// Providers list with search and filters (A08).
class ProvidersPage extends StatefulWidget {
  /// Creates the page.
  const ProvidersPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  late final _Cubit _cubit = _Cubit(
    const ProviderFilter(),
    ApiProvidersRepository(widget.services.api).list,
  ).loading();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  List<AdminColumn<AdminProviderSummary>> _columns(AdminL10n t, bool wide) => [
    AdminColumn(t.peopleName, (p) => _NameCell(provider: p), flex: 3),
    AdminColumn(
      t.peopleFilterStatus,
      (p) => StatusCell(
        label: accountStatusLabel(t, p.status),
        tone: accountStatusTone(p.status),
      ),
      flex: 2,
    ),
    AdminColumn(t.providersLevel, (p) => Text(levelLabel(t, p.level)), flex: 2),
    AdminColumn(t.peopleRating, (p) => Text(context.rating(p.rating))),
    if (wide) ...[
      AdminColumn(t.providersJobs, (p) => Text(context.count(p.completedJobs))),
      AdminColumn(
        t.peopleJoined,
        (p) => Text(context.when(p.createdAt, 'd MMM y')),
        flex: 2,
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider<PagedCubit<AdminProviderSummary>>.value(
      value: _cubit,
      child: LayoutBuilder(
        builder: (context, box) => PagedTable<AdminProviderSummary>(
          header: [
            ListHeading(t.providersTitle),
            _Filters(cubit: _cubit),
          ],
          columns: _columns(t, box.maxWidth >= twoColumnWidth),
          empty: PaoEmptyState(title: t.providersEmpty),
          onOpen: (p) => context.go(Routes.detail(Routes.providers, p.id)),
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.provider});

  final AdminProviderSummary provider;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Flexible(child: Text(provider.name, overflow: TextOverflow.ellipsis)),
          if (provider.flaggedForReview)
            Tooltip(
              message: context.t.providersFlagged,
              child: const Icon(Icons.flag, size: 16, color: PaoColors.danger),
            ),
        ],
      ),
      if (provider.phone case final phone?)
        Text(phone, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _Filters extends StatelessWidget {
  const _Filters({required this.cubit});

  final _Cubit cubit;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<_Cubit, PagedState<AdminProviderSummary>>(
        bloc: cubit,
        builder: (context, _) => _bar(context),
      );

  Widget _bar(BuildContext context) {
    final t = context.t;
    final f = cubit.filter;
    return FilterBar(
      searchHint: t.providersSearch,
      search: (q) => cubit.apply(f.searching(q)),
      filters: [
        FilterMenu<AccountStatus>(
          label: t.peopleFilterStatus,
          options: accountStatusOptions(t),
          value: f.status,
          onChanged: (s) => cubit.apply(f.withStatus(s)),
        ),
        FilterMenu<int>(
          label: t.providersLevel,
          options: {
            null: t.peopleFilterAny,
            for (final l in providerLevels) l: levelLabel(t, l),
          },
          value: f.level,
          onChanged: (l) => cubit.apply(f.withLevel(l)),
        ),
        PaoChip(
          label: t.providersFlagged,
          selected: f.flagged,
          onTap: () => cubit.apply(f.toggleFlagged()),
        ),
      ],
    );
  }
}
