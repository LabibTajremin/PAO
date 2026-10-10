import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/data/api_admin_auth_repository.dart';
import 'package:pao_admin/features/auth/data/session_restore.dart';
import 'package:pao_admin/features/auth/presentation/auth_frame.dart';
import 'package:pao_admin/features/auth/presentation/login_cubit.dart';
import 'package:pao_admin/features/auth/presentation/totp_step.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Login with email, password and an authenticator code (A01).
class LoginPage extends StatefulWidget {
  /// Creates the page.
  const LoginPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signedIn(String token, {required bool mustChange}) async {
    widget.services.mustChangePassword.value = mustChange;
    await startSession(widget.services, token);
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoginCubit(
      ApiAdminAuthRepository(widget.services.api),
      onSignedIn: _signedIn,
    ),
    child: BlocBuilder<LoginCubit, LoginState>(
      builder: (context, s) => AuthFrame(
        title: context.t.loginTitle,
        children: s.challenge == null
            ? _credentials(context, s)
            : [TotpStep(state: s, cubit: context.read<LoginCubit>())],
      ),
    ),
  );

  List<Widget> _credentials(BuildContext context, LoginState s) => [
    PaoTextField(
      label: context.t.loginEmail,
      controller: _email,
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: PaoSpace.lg),
    PaoTextField(
      label: context.t.loginPassword,
      controller: _password,
      obscureText: true,
      error: context.failureText(s.failure),
    ),
    const SizedBox(height: PaoSpace.xl),
    PaoButton(
      label: context.t.loginSubmit,
      loading: s.busy,
      onPressed: () =>
          context.read<LoginCubit>().login(_email.text, _password.text),
    ),
  ];
}
