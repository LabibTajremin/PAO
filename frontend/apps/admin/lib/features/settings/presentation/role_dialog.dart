import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Edits what [role] may do and see, picking from [list]'s permissions and
/// screens; asks before applying since it changes access at once.
Future<void> showRoleDialog(
  BuildContext context, {
  required RolesCubit cubit,
  required RoleList list,
  required RoleDefinition role,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _RoleDialog(cubit: cubit, list: list, role: role),
  );
  if ((saved ?? false) && context.mounted) {
    showDone(context, context.t.rolesSaved);
  }
}

class _RoleDialog extends StatefulWidget {
  const _RoleDialog({
    required this.cubit,
    required this.list,
    required this.role,
  });

  final RolesCubit cubit;
  final RoleList list;
  final RoleDefinition role;

  @override
  State<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<_RoleDialog> {
  late final Set<String> _permissions = widget.role.permissions.toSet();
  late final Set<String> _screens = widget.role.screens.toSet();
  var _busy = false;
  AppFailure? _failure;

  Future<void> _save() async {
    final t = context.t;
    final name = roleLabel(t, widget.role.role.value);
    final apply = await confirmAction(
      context,
      title: t.rolesConfirmTitle(name),
      body: t.rolesApplyNow,
      confirmLabel: t.rolesApply,
    );
    if (!apply || !mounted) return;
    setState(() => _busy = true);
    final failure = await widget.cubit.save(
      widget.role.role,
      RoleUpdate(
        permissions: _permissions.toList(),
        screens: _screens.toList(),
      ),
    );
    if (!mounted) return;
    if (failure == null) return Navigator.pop(context, true);
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: roleLabel(context.t, widget.role.role.value),
    width: 640,
    busy: _busy,
    onSave: _save,
    children: [
      PaoBanner(
        message: context.t.rolesApplyNow,
        icon: Icons.warning_amber_outlined,
      ),
      _Picks(
        title: context.t.rolesPermissions,
        all: widget.list.allPermissions,
        picked: _permissions,
        onChanged: () => setState(() {}),
      ),
      _Picks(
        title: context.t.rolesScreens,
        all: widget.list.allScreens,
        picked: _screens,
        onChanged: () => setState(() {}),
      ),
      if (_failure != null) FormError(context.failureText(_failure)!),
    ],
  );
}

class _Picks extends StatelessWidget {
  const _Picks({
    required this.title,
    required this.all,
    required this.picked,
    required this.onChanged,
  });

  final String title;
  final List<String> all;
  final Set<String> picked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: PaoSpace.sm,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      Wrap(
        spacing: PaoSpace.sm,
        runSpacing: PaoSpace.sm,
        children: [
          for (final item in all)
            FilterChip(
              label: Text(item),
              selected: picked.contains(item),
              onSelected: (on) {
                if (on) {
                  picked.add(item);
                } else {
                  picked.remove(item);
                }
                onChanged();
              },
            ),
        ],
      ),
    ],
  );
}
