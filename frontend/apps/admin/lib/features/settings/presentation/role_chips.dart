import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Picks the roles of an admin user.
class RoleChips extends StatelessWidget {
  /// Creates the chips.
  const RoleChips({
    required this.selected,
    required this.onChanged,
    this.error,
    super.key,
  });

  /// Roles picked so far.
  final Set<AdminRole> selected;

  /// Called with the new selection.
  final ValueChanged<Set<AdminRole>> onChanged;

  /// Problem with the selection.
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: PaoSpace.sm,
    children: [
      Text(
        context.t.adminsRoles,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      Wrap(
        spacing: PaoSpace.sm,
        runSpacing: PaoSpace.sm,
        children: [
          for (final role in AdminRole.values)
            FilterChip(
              label: Text(roleLabel(context.t, role.value)),
              selected: selected.contains(role),
              onSelected: (on) => onChanged(
                on ? {...selected, role} : ({...selected}..remove(role)),
              ),
            ),
        ],
      ),
      if (error != null) FormError(error!),
    ],
  );
}
