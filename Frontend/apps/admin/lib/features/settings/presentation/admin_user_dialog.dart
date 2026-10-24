import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/presentation/role_chips.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Changes [user]'s roles or deactivates them; deactivating asks first since
/// it ends their sessions at once.
Future<void> showAdminUserDialog(
  BuildContext context, {
  required AdminUsersCubit cubit,
  required AdminUser user,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _AdminUserDialog(cubit: cubit, user: user),
  );
  if ((saved ?? false) && context.mounted) {
    showDone(context, context.t.formSaved);
  }
}

class _AdminUserDialog extends StatefulWidget {
  const _AdminUserDialog({required this.cubit, required this.user});

  final AdminUsersCubit cubit;
  final AdminUser user;

  @override
  State<_AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends State<_AdminUserDialog> {
  late Set<AdminRole> _roles = widget.user.roles.toSet();
  late bool _active = widget.user.active;
  String? _rolesError;
  var _busy = false;
  AppFailure? _failure;

  Future<bool> _confirmDeactivate() => confirmAction(
    context,
    title: context.t.adminsDeactivateTitle(widget.user.name),
    body: context.t.adminsDeactivateBody,
    confirmLabel: context.t.adminsDeactivate,
  );

  Future<void> _save() async {
    _rolesError = _roles.isEmpty ? context.t.adminsPickRole : null;
    if (_rolesError != null) return setState(() {});
    final deactivating = widget.user.active && !_active;
    if (deactivating && !await _confirmDeactivate()) return;
    setState(() => _busy = true);
    final failure = await widget.cubit.update(
      widget.user.id,
      AdminUserUpdate(roles: _roles.toList(), active: _active),
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
    title: widget.user.name,
    busy: _busy,
    onSave: _save,
    children: [
      Text(widget.user.email),
      RoleChips(
        selected: _roles,
        error: _rolesError,
        onChanged: (roles) => setState(() => _roles = roles),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.t.adminsActiveSwitch),
        subtitle: Text(context.t.adminsActiveHint),
        value: _active,
        onChanged: (v) => setState(() => _active = v),
      ),
      if (_failure != null) FormError(context.failureText(_failure)!),
    ],
  );
}
