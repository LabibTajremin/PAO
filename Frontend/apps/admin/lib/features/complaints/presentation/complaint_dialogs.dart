import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/shared/confirm_reason.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// How a complaint was closed.
typedef Resolution = ({String note, bool verified});

/// Asks for the resolution note and whether the complaint is verified;
/// resolves with null if the admin cancels.
Future<Resolution?> askResolution(BuildContext context, String ticket) =>
    showDialog<Resolution>(
      context: context,
      builder: (_) => _ResolveDialog(ticket: ticket),
    );

class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog({required this.ticket});

  final String ticket;

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _note = TextEditingController();
  var _verified = false;
  var _short = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _note.text.trim();
    if (note.length < minReasonLength) return setState(() => _short = true);
    Navigator.pop<Resolution>(context, (note: note, verified: _verified));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.complaintsResolveTitle(widget.ticket)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaoTextField(
              label: t.complaintsResolution,
              controller: _note,
              maxLines: 3,
              error: _short ? t.reasonTooShort(minReasonLength) : null,
            ),
            CheckboxListTile(
              value: _verified,
              onChanged: (v) => setState(() => _verified = v!),
              title: Text(t.complaintsVerified),
              subtitle: Text(t.complaintsVerifiedHelp),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.common.actionCancel),
        ),
        FilledButton(onPressed: _confirm, child: Text(t.complaintsResolve)),
      ],
    );
  }
}

/// Lets the admin pick an active support agent from [load]; resolves with
/// their ID, or null if cancelled.
Future<String?> pickAgent(
  BuildContext context,
  Future<List<AdminUser>> Function() load,
) => showDialog<String>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => LoadCubit<List<AdminUser>>(load).loading(),
    child: const _AgentPicker(),
  ),
);

class _AgentPicker extends StatelessWidget {
  const _AgentPicker();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cubit = context.watch<LoadCubit<List<AdminUser>>>();
    return AlertDialog(
      title: Text(t.complaintsPickAgent),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: ViewStateView<List<AdminUser>>(
            state: cubit.state,
            onRetry: cubit.load,
            isEmpty: (agents) => agents.isEmpty,
            empty: Text(t.complaintsNoAgents),
            builder: (context, agents) => Column(
              children: [
                for (final a in agents)
                  ListTile(
                    leading: PaoAvatar(name: a.name, size: 36),
                    title: Text(a.name),
                    subtitle: Text(a.email),
                    onTap: () => Navigator.pop(context, a.id),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.common.actionCancel),
        ),
      ],
    );
  }
}
