import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/features/catalog/presentation/schedule_draft.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The ordering rules of a scheduled-delivery service (ADR-0041 §1).
class ScheduleFields extends StatelessWidget {
  /// Creates the fields.
  const ScheduleFields({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
  });

  /// The rules being edited.
  final ScheduleDraft draft;

  /// Field errors from the last check.
  final FormErrors errors;

  /// Rebuilds the form after a choice.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    Widget number(String label, TextEditingController c) => SizedBox(
      width: 200,
      child: PaoTextField(
        label: label,
        controller: c,
        keyboardType: TextInputType.number,
        error: errors.of(c),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaoSpace.md,
      children: [
        Text(t.catalogSchedule, style: Theme.of(context).textTheme.titleSmall),
        Text(t.catalogPatterns),
        Wrap(
          spacing: PaoSpace.sm,
          children: [
            for (final p in DeliveryPattern.values)
              PaoChip(
                label: patternLabel(t, p),
                selected: draft.patterns.contains(p),
                onTap: () {
                  draft.patterns.contains(p)
                      ? draft.patterns.remove(p)
                      : draft.patterns.add(p);
                  onChanged();
                },
              ),
          ],
        ),
        if (draft.patternError case final why?)
          Text(why, style: TextStyle(color: context.pao.dangerInk)),
        PaoTextField(
          label: t.catalogWindows,
          hint: t.catalogWindowsHint,
          controller: draft.windows,
          error: errors.of(draft.windows),
        ),
        Wrap(
          spacing: PaoSpace.lg,
          runSpacing: PaoSpace.lg,
          children: [
            number(t.catalogLeadHours, draft.lead),
            SizedBox(
              width: 200,
              child: PaoTextField(
                label: t.catalogCutoff,
                controller: draft.cutoff,
                error: errors.of(draft.cutoff),
              ),
            ),
            number(t.catalogScheduleMin, draft.min),
            number(t.catalogScheduleMax, draft.max),
            SizedBox(width: 200, child: _unit(context)),
          ],
        ),
      ],
    );
  }

  Widget _unit(BuildContext context) => DropdownButtonFormField<QuantityUnit>(
    initialValue: draft.unit,
    decoration: InputDecoration(labelText: context.t.catalogScheduleUnit),
    items: [
      for (final u in QuantityUnit.values)
        DropdownMenuItem(value: u, child: Text(quantityLabel(context.t, u))),
    ],
    onChanged: (u) {
      draft.unit = u!;
      onChanged();
    },
  );
}
