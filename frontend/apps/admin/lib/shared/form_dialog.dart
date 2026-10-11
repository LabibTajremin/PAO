import 'package:flutter/material.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A dialog holding a form: [children] scroll above Cancel and a save button
/// that shows [busy] while the save runs.
class FormDialog extends StatelessWidget {
  /// Creates the dialog.
  const FormDialog({
    required this.title,
    required this.onSave,
    required this.children,
    this.busy = false,
    this.saveLabel,
    this.width = 560,
    super.key,
  });

  /// Heading.
  final String title;

  /// Checks and saves the form.
  final VoidCallback onSave;

  /// Fields, top to bottom.
  final List<Widget> children;

  /// A save is in flight.
  final bool busy;

  /// Label of the save button; "Save" when null.
  final String? saveLabel;

  /// Width of the content.
  final double width;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaoSpace.lg,
          children: children,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.common.actionCancel),
      ),
      PaoButton(
        label: saveLabel ?? context.common.actionSave,
        expand: false,
        loading: busy,
        onPressed: onSave,
      ),
    ],
  );
}

/// Asks the admin to confirm an action that takes effect at once; resolves
/// with true only when [confirmLabel] is pressed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.common.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return yes ?? false;
}

/// [message] in red under a form, e.g. why the API refused it.
class FormError extends StatelessWidget {
  /// Creates the message.
  const FormError(this.message, {super.key});

  /// What went wrong.
  final String message;

  @override
  Widget build(BuildContext context) =>
      Text(message, style: const TextStyle(color: PaoColors.danger));
}
