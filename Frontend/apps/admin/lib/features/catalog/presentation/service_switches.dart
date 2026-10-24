import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/localized_list.dart';
import 'package:pao_admin/features/catalog/presentation/service_draft.dart';
import 'package:pao_admin/shared/l10n.dart';

/// The yes/no rules of a service, with the Level 2 checklist when a skill
/// check is required.
class ServiceSwitches extends StatelessWidget {
  /// Creates the switches.
  const ServiceSwitches({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  /// The form values.
  final ServiceDraft draft;

  /// Rebuilds the form after a change.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _switch(
          title: t.catalogWomenOnly,
          hint: t.catalogWomenOnlyHint,
          value: draft.womenOnly,
          set: (v) => draft.womenOnly = v,
        ),
        _switch(
          title: t.catalogRequiresLevel2,
          hint: t.catalogRequiresLevel2Hint,
          value: draft.requiresLevel2,
          set: (v) => draft.requiresLevel2 = v,
        ),
        if (draft.requiresLevel2)
          LocalizedList(
            title: t.catalogChecklistItem,
            items: draft.checklist,
            errors: draft.errors,
            onChanged: onChanged,
          ),
        _switch(
          title: t.catalogPublishedSwitch,
          hint: t.catalogPublishedHint,
          value: draft.published,
          set: (v) => draft.published = v,
        ),
      ],
    );
  }

  Widget _switch({
    required String title,
    required String hint,
    required bool value,
    required ValueChanged<bool> set,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(hint),
    value: value,
    onChanged: (v) {
      set(v);
      onChanged();
    },
  );
}
