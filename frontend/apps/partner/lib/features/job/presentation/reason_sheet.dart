import 'package:flutter/material.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A reason picked in a [ReasonSheet], with an optional note.
typedef ReasonChoice<T> = (T reason, String? note);

/// Shows [form] in a bottom sheet titled [title]; null when dismissed.
Future<ReasonChoice<T>?> showReasonSheet<T>(
  BuildContext context, {
  required String title,
  required ReasonSheet<T> form,
}) => showPaoSheet<ReasonChoice<T>>(context, title: title, child: form);

/// Fixed reasons as chips, a note and a confirm button (reject and cancel).
class ReasonSheet<T> extends StatefulWidget {
  /// Creates the form.
  const ReasonSheet({
    required this.reasons,
    required this.confirm,
    this.warning,
    super.key,
  });

  /// Label per reason, in order.
  final Map<T, String> reasons;

  /// Confirm button text.
  final String confirm;

  /// Consequence shown above the reasons.
  final String? warning;

  @override
  State<ReasonSheet<T>> createState() => _ReasonSheetState<T>();
}

class _ReasonSheetState<T> extends State<ReasonSheet<T>> {
  final _note = TextEditingController();
  T? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _note.text.trim();
    Navigator.of(context).pop((_reason as T, note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.warning != null) ...[
        Text(widget.warning!, style: const TextStyle(color: PaoColors.warning)),
        const SizedBox(height: PaoSpace.md),
      ],
      Wrap(
        spacing: PaoSpace.sm,
        runSpacing: PaoSpace.sm,
        children: [
          for (final MapEntry(:key, :value) in widget.reasons.entries)
            PaoChip(
              label: value,
              selected: _reason == key,
              onTap: () => setState(() => _reason = key),
            ),
        ],
      ),
      const SizedBox(height: PaoSpace.lg),
      PaoTextField(label: context.t.jobNoteLabel, controller: _note),
      const SizedBox(height: PaoSpace.lg),
      PaoButton(
        label: widget.confirm,
        variant: PaoButtonVariant.danger,
        onPressed: _reason == null ? null : _confirm,
      ),
    ],
  );
}
