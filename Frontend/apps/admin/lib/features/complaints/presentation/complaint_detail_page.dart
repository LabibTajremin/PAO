import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/complaints/data/api_complaints_repository.dart';
import 'package:pao_admin/features/complaints/domain/complaints_repository.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_actions.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_comments.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_overview.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/ops/record_cubit.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

typedef _Cubit = RecordCubit<ComplaintCase>;

/// One complaint: what happened, evidence, internal comments, and assign
/// and resolve for admins holding `complaint:manage` (A11).
class ComplaintDetailPage extends StatelessWidget {
  /// Creates the page for complaint [id].
  const ComplaintDetailPage({
    required this.services,
    required this.id,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The complaint's ID.
  final String id;

  /// Runs [action] and reports [done] or why it failed.
  Future<bool> _run(
    BuildContext context,
    ComplaintCase kase,
    Future<Complaint> Function() action,
    String done,
  ) async {
    final failure = await context.read<_Cubit>().act(
      () async => kase.updated(await action()),
    );
    if (context.mounted) showOutcome(context, failure, done);
    return failure == null;
  }

  ComplaintHandlers _handlers(
    BuildContext context,
    ComplaintsRepository repo,
    ComplaintCase kase,
  ) {
    final t = context.t;
    return ComplaintHandlers(
      assign: (agent) => _run(
        context,
        kase,
        () => repo.assign(id, agent),
        t.complaintsAssigned,
      ),
      resolve: (r) => _run(
        context,
        kase,
        () => repo.resolve(id, resolution: r.note, verified: r.verified),
        t.complaintsResolved,
      ),
      comment: (body) => _run(
        context,
        kase,
        () => repo.comment(id, body),
        t.complaintsCommented,
      ),
      agents: services.permissions.can('admin_user:manage')
          ? repo.agents
          : null,
    );
  }

  Widget _body(
    BuildContext context,
    ComplaintsRepository repo,
    ComplaintCase c,
  ) {
    final handlers = _handlers(context, repo, c);
    final open = c.complaint.status != ComplaintStatus.resolved;
    return SplitColumns(
      first: [
        ComplaintOverview(kase: c, permissions: services.permissions),
        ComplaintEvidence(photoIds: c.complaint.photoMediaIds ?? const []),
        ComplaintComments(kase: c, onSend: handlers.comment),
      ],
      second: [
        if (open && services.permissions.can('complaint:manage'))
          ComplaintActions(kase: c, handlers: handlers),
        if (!open) ComplaintResolution(complaint: c.complaint),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ApiComplaintsRepository(services.api);
    return BlocProvider(
      create: (_) => _Cubit(
        () async => ComplaintCase(await repo.detail(id), await repo.me()),
      ).loading(),
      child: BlocBuilder<_Cubit, ViewState<ComplaintCase>>(
        builder: (context, state) => DetailFrame<ComplaintCase>(
          back: BackLink(label: context.t.complaintsAll, to: Routes.complaints),
          state: state,
          onRetry: context.read<_Cubit>().load,
          builder: (context, c) => _body(context, repo, c),
        ),
      ),
    );
  }
}
