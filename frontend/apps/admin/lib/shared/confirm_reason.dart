import 'package:flutter/material.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Shortest reason accepted; the API asks for at least five characters too.
const minReasonLength = 5;

/// Asks the admin to confirm [title] with a written reason, offering
/// [templates] to start from; resolves with the reason, or null if cancelled.
Future<String?> confirmWithReason(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  List<String> templates = const [],
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(
    title: title,
    confirmLabel: confirmLabel,
    templates: templates,
  ),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.confirmLabel,
    required this.templates,
  });

  final String title;
  final String confirmLabel;
  final List<String> templates;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();
  var _short = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _reason.text.trim();
    if (text.length < minReasonLength) return setState(() => _short = true);
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: PaoSpace.sm,
            runSpacing: PaoSpace.sm,
            children: [
              for (final t in widget.templates)
                ActionChip(label: Text(t), onPressed: () => _reason.text = t),
            ],
          ),
          const SizedBox(height: PaoSpace.md),
          PaoTextField(
            label: context.t.reasonLabel,
            controller: _reason,
            maxLines: 3,
            error: _short ? context.t.reasonTooShort(minReasonLength) : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.common.actionCancel),
      ),
      FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
    ],
  );
}
