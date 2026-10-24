import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/data/api_admin_auth_repository.dart';
import 'package:pao_admin/features/auth/presentation/auth_frame.dart';
import 'package:pao_admin/features/auth/presentation/password_cubit.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Replaces the temporary password from the invite before the console opens.
class PasswordPage extends StatefulWidget {
  /// Creates the page.
  const PasswordPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  String? _error(BuildContext context, PasswordState s) => switch (s.problem) {
    PasswordProblem.tooShort => context.t.passwordTooShort,
    PasswordProblem.mismatch => context.t.passwordMismatch,
    null => context.failureText(s.failure),
  };

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PasswordCubit(ApiAdminAuthRepository(widget.services.api)),
    child: BlocConsumer<PasswordCubit, PasswordState>(
      listenWhen: (_, s) => s.done,
      // The router's password gate moves on once the flag clears.
      listener: (_, _) => widget.services.mustChangePassword.value = false,
      builder: (context, s) => AuthFrame(
        title: context.t.passwordTitle,
        children: [
          Text(context.t.passwordBody),
          const SizedBox(height: PaoSpace.xl),
          for (final (label, field) in [
            (context.t.passwordCurrent, _current),
            (context.t.passwordNew, _next),
            (context.t.passwordRepeat, _repeat),
          ]) ...[
            PaoTextField(label: label, controller: field, obscureText: true),
            const SizedBox(height: PaoSpace.lg),
          ],
          if (_error(context, s) case final error?)
            Text(error, style: const TextStyle(color: PaoColors.danger)),
          const SizedBox(height: PaoSpace.lg),
          PaoButton(
            label: context.common.actionSave,
            loading: s.busy,
            onPressed: () => context.read<PasswordCubit>().change(
              _current.text,
              _next.text,
              _repeat.text,
            ),
          ),
        ],
      ),
    ),
  );
}
