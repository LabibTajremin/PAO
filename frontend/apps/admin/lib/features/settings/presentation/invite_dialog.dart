import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pao_admin/features/settings/presentation/role_chips.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Invites an admin, then shows the temporary password once.
Future<void> showInviteDialog(
  BuildContext context, {
  required AdminUsersCubit cubit,
}) async {
  final invited = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _InviteDialog(cubit: cubit),
  );
  if (invited == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PasswordDialog(name: invited.$1, password: invited.$2),
  );
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.cubit});

  final AdminUsersCubit cubit;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _errors = FormErrors();
  var _roles = <AdminRole>{};
  String? _rolesError;
  var _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _address.dispose();
    _name.dispose();
    super.dispose();
  }

  bool _check() {
    final t = context.t;
    final address = _address.text.trim();
    final name = _name.text.trim();
    _errors
      ..set(_address, _email.hasMatch(address) ? null : t.formEmail)
      ..set(
        _name,
        name.length == 1 ? t.adminsNameShort : checkText(t, name, max: 80),
      );
    _rolesError = _roles.isEmpty ? t.adminsPickRole : null;
    return _errors.isEmpty && _rolesError == null;
  }

  Future<void> _save() async {
    if (!_check()) return setState(() {});
    setState(() => _busy = true);
    final name = _name.text.trim();
    final (password, failure) = await widget.cubit.invite(
      AdminUserInvite(
        email: _address.text.trim(),
        name: name,
        roles: _roles.toList(),
      ),
    );
    if (!mounted) return;
    if (failure == null) return Navigator.pop(context, (name, password!));
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: context.t.adminsInvite,
    saveLabel: context.t.adminsSendInvite,
    busy: _busy,
    onSave: _save,
    children: [
      PaoTextField(
        label: context.t.adminsEmail,
        controller: _address,
        keyboardType: TextInputType.emailAddress,
        error: _errors.of(_address),
      ),
      PaoTextField(
        label: context.t.adminsName,
        controller: _name,
        error: _errors.of(_name),
      ),
      RoleChips(
        selected: _roles,
        error: _rolesError,
        onChanged: (roles) => setState(() => _roles = roles),
      ),
      if (_failure != null) FormError(context.failureText(_failure)!),
    ],
  );
}

class _PasswordDialog extends StatelessWidget {
  const _PasswordDialog({required this.name, required this.password});

  final String name;
  final String password;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.t.adminsInvitedTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PaoSpace.md,
      children: [
        Text(context.t.adminsInvitedBody(name)),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                password,
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontFamily: 'monospace'),
              ),
            ),
            IconButton(
              tooltip: context.t.adminsCopy,
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: password));
                if (context.mounted) showDone(context, context.t.adminsCopied);
              },
            ),
          ],
        ),
      ],
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.t.adminsDone),
      ),
    ],
  );
}
