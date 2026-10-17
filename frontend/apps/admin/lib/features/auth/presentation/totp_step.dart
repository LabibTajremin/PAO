import 'package:flutter/material.dart';
import 'package:pao_admin/features/auth/presentation/login_cubit.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The authenticator step of A01; on the first login it shows the key to add.
class TotpStep extends StatelessWidget {
  /// Creates the step for [state].
  const TotpStep({required this.state, required this.cubit, super.key});

  /// Login state with its challenge.
  final LoginState state;

  /// Runs the step.
  final LoginCubit cubit;

  @override
  Widget build(BuildContext context) {
    final secret = state.challenge!.enrolSecret;
    final wrong = state.failure?.code == 'TOTP_INVALID';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (secret != null) ...[
          Text(context.t.loginEnrolBody),
          const SizedBox(height: PaoSpace.sm),
          SelectableText(
            secret,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PaoSpace.lg),
        ],
        Text(context.t.loginCodeBody),
        const SizedBox(height: PaoSpace.lg),
        PaoOtpInput(
          onCompleted: cubit.verify,
          hasError: wrong,
          semanticLabel: context.t.loginCodeBody,
        ),
        if (state.failure != null) ...[
          const SizedBox(height: PaoSpace.md),
          Text(
            context.failureText(state.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        ],
        if (state.busy) const Center(child: CircularProgressIndicator()),
        const SizedBox(height: PaoSpace.lg),
        TextButton(onPressed: cubit.restart, child: Text(context.t.loginBack)),
      ],
    );
  }
}
