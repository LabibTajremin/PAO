import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/features/settings/presentation/audit_detail.dart';
import 'package:pao_admin/features/settings/presentation/audit_filters.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/detail_drawer.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// The audit log, newest first, filtered by actor, action, subject and dates
/// (A-08); a row opens the entry with its before and after values.
class AuditTab extends StatefulWidget {
  /// Creates the tab.
  const AuditTab({required this.repository, required this.now, super.key});

  /// Reads the log.
  final SettingsRepository repository;

  /// Current time, the latest date the range picker offers.
  final DateTime Function() now;

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  var _filter = const AuditFilter();
  // A new filter starts a new list from the first page.
  var _version = 0;

  void _apply(AuditFilter filter) => setState(() {
    _filter = filter;
    _version++;
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final filter = _filter;
    return BlocProvider<PagedCubit<AuditEntry>>(
      key: ValueKey(_version),
      create: (_) => PagedCubit<AuditEntry>(
        (cursor) => widget.repository.audit(filter, cursor: cursor),
      ).loading(),
      child: PagedTable<AuditEntry>(
        header: [
          AuditFilters(filter: filter, now: widget.now, onApply: _apply),
        ],
        columns: [
          AdminColumn(t.auditWhen, (e) => Text(context.when(e.at)), flex: 2),
          AdminColumn(t.auditActor, (e) => Text(_actor(t, e)), flex: 2),
          AdminColumn(t.auditAction, (e) => Text(e.action), flex: 3),
          AdminColumn(
            t.auditSubject,
            (e) => Text('${e.subjectType} · ${e.subjectId}'),
            flex: 3,
          ),
        ],
        empty: PaoEmptyState(title: t.auditEmpty),
        onOpen: (e) => showDetailDrawer<void>(
          context,
          title: e.action,
          child: AuditDetail(entry: e),
        ),
      ),
    );
  }

  String _actor(AdminL10n t, AuditEntry e) {
    final role = e.actorRole;
    final id = e.actorId;
    if (id == null) return t.auditSystem;
    final short = id.substring(0, 8);
    return role == null ? short : '${roleLabel(t, role)} · $short';
  }
}
