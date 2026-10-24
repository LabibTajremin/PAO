import 'package:flutter/material.dart';
import 'package:pao_admin/features/complaints/domain/complaints_repository.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_dialogs.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// What the actions on a complaint do; each resolves with whether it worked.
class ComplaintHandlers {
  /// Creates the handlers; a null [agents] hides "Assign to…".
  const ComplaintHandlers({
    required this.assign,
    required this.resolve,
    required this.comment,
    this.agents,
  });

  /// Assigns the complaint to an admin.
  final Future<bool> Function(String assigneeId) assign;

  /// Closes the complaint.
  final Future<bool> Function(Resolution resolution) resolve;

  /// Adds an internal comment.
  final Future<bool> Function(String body) comment;

  /// Loads the agents to assign to, for admins who may list them.
  final Future<List<AdminUser>> Function()? agents;
}

/// Assign and resolve buttons for an open or assigned complaint.
class ComplaintActions extends StatelessWidget {
  /// Creates the section.
  const ComplaintActions({
    required this.kase,
    required this.handlers,
    super.key,
  });

  /// The complaint.
  final ComplaintCase kase;

  /// What the buttons do.
  final ComplaintHandlers handlers;

  Future<void> _assignOther(BuildContext context) async {
    final agent = await pickAgent(context, handlers.agents!);
    if (agent != null) await handlers.assign(agent);
  }

  Future<void> _resolve(BuildContext context) async {
    final res = await askResolution(context, kase.complaint.ticketNumber);
    if (res != null) await handlers.resolve(res);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mine = kase.complaint.assigneeId == kase.me;
    return Section(
      title: t.complaintsActions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaoSpace.sm,
        children: [
          if (!mine)
            PaoButton(
              label: t.complaintsAssignMe,
              variant: PaoButtonVariant.soft,
              onPressed: () => handlers.assign(kase.me),
            ),
          if (handlers.agents != null)
            PaoButton(
              label: t.complaintsAssignOther,
              variant: PaoButtonVariant.outline,
              onPressed: () => _assignOther(context),
            ),
          PaoButton(
            label: t.complaintsResolve,
            onPressed: () => _resolve(context),
          ),
        ],
      ),
    );
  }
}
