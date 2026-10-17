import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// One audit entry in full, with the before and after values as JSON.
class AuditDetail extends StatelessWidget {
  /// Creates the detail.
  const AuditDetail({required this.entry, super.key});

  /// The entry.
  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final role = entry.actorRole;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaoSpace.md,
      children: [
        _Line(t.auditWhen, context.when(entry.at)),
        _Line(t.auditActor, entry.actorId ?? t.auditSystem),
        if (role != null) _Line(t.auditRole, roleLabel(t, role)),
        _Line(t.auditAction, entry.action),
        _Line(t.auditSubject, '${entry.subjectType} · ${entry.subjectId}'),
        if (entry.reason != null) _Line(t.auditReason, entry.reason!),
        if (entry.before != null) _Json(t.auditBefore, entry.before!),
        if (entry.after != null) _Json(t.auditAfter, entry.after!),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: PaoColors.textSecondary),
      ),
      SelectableText(value),
    ],
  );
}

class _Json extends StatelessWidget {
  const _Json(this.label, this.value);

  final String label;
  final Map<String, Object?> value;

  @override
  Widget build(BuildContext context) =>
      _Line(label, const JsonEncoder.withIndent('  ').convert(value));
}
