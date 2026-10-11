import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/level2/presentation/level2_labels.dart';
import 'package:pao_admin/features/level2/presentation/provider_filter.dart';
import 'package:pao_admin/features/level2/presentation/schedule_dialog.dart';
import 'package:pao_admin/features/level2/presentation/session_view.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/features/verification/presentation/page_header.dart';
import 'package:pao_admin/shared/detail_drawer.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Level 2 sessions: filter, schedule, open and record (A07).
class Level2Page extends StatefulWidget {
  /// Creates the page.
  const Level2Page({
    required this.repo,
    required this.permissions,
    required this.now,
    super.key,
  });

  /// Where sessions come from.
  final Level2Repository repo;

  /// What the admin may do.
  final PermissionService permissions;

  /// Current time.
  final DateTime Function() now;

  @override
  State<Level2Page> createState() => _Level2PageState();
}

class _Level2PageState extends State<Level2Page> {
  Level2SessionStatusEnum? _status;
  AdminProviderSummary? _provider;
  var _generation = 0;

  bool get _canManage => widget.permissions.can(level2Permission);

  void _reload() => setState(() => _generation++);

  Future<void> _schedule() async {
    final booked = await showScheduleDialog(
      context,
      repo: widget.repo,
      now: widget.now,
    );
    if (booked == null || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t.level2Booked)));
  }

  @override
  Widget build(BuildContext context) {
    final canSchedule =
        _canManage && widget.permissions.can(providerReadPermission);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: context.t.level2Title,
          actions: [
            if (canSchedule)
              PaoButton(
                label: context.t.level2Schedule,
                icon: Icons.event_available,
                expand: false,
                onPressed: _schedule,
              ),
          ],
        ),
        Expanded(child: _table(context)),
      ],
    );
  }

  Widget _table(BuildContext context) => BlocProvider(
    key: ValueKey((_status, _provider?.id, _generation)),
    create: (_) => PagedCubit<Level2Row>(
      (cursor) => widget.repo.sessions(
        providerId: _provider?.id,
        status: _status,
        cursor: cursor,
      ),
    ).loading(),
    child: PagedTable<Level2Row>(
      header: [FilterBar(filters: _filters(context))],
      columns: _columns(context),
      empty: PaoEmptyState(title: context.t.level2Empty),
      onOpen: (row) => showDetailDrawer<void>(
        context,
        title: context.t.level2SessionTitle,
        child: SessionPanel(
          repo: widget.repo,
          id: row.session.id,
          canRecord: _canManage,
          onRecorded: _reload,
        ),
      ),
    ),
  );

  List<Widget> _filters(BuildContext context) => [
    DropdownMenu<Level2SessionStatusEnum?>(
      width: 220,
      label: Text(context.t.level2FilterStatus),
      initialSelection: _status,
      onSelected: (value) => setState(() => _status = value),
      dropdownMenuEntries: [
        DropdownMenuEntry(value: null, label: context.t.level2AllStatuses),
        for (final s in Level2SessionStatusEnum.values)
          DropdownMenuEntry(value: s, label: sessionStatusLabel(context.t, s)),
      ],
    ),
    if (widget.permissions.can(providerReadPermission))
      ProviderFilter(
        repo: widget.repo,
        selected: _provider,
        onChanged: (p) => setState(() => _provider = p),
      ),
  ];

  List<AdminColumn<Level2Row>> _columns(BuildContext context) {
    final t = context.t;
    return [
      AdminColumn(
        t.level2ColWhen,
        (r) => Text(context.when(r.session.scheduledAt)),
        flex: 2,
      ),
      AdminColumn(
        t.level2ColProvider,
        (r) => Text(context.providerOf(r)),
        flex: 2,
      ),
      AdminColumn(t.level2ColService, (r) => Text(context.serviceOf(r))),
      AdminColumn(t.level2Location, (r) => Text(r.session.location), flex: 2),
      AdminColumn(t.level2ColStatus, (r) => _Status(row: r)),
    ];
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.row});

  final Level2Row row;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final result = row.session.result;
    // Scaled down rather than clipped when the column is narrow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: result == null
          ? PaoBadge(label: sessionStatusLabel(t, row.session.status))
          : PaoBadge(label: resultLabel(t, result), tone: resultTone(result)),
    );
  }
}
