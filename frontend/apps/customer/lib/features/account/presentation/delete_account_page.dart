import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/data/api_account_repository.dart';
import 'package:pao_customer/features/account/data/sign_out.dart';
import 'package:pao_customer/features/account/presentation/delete_account_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Delete account (C29), confirmed with a code (C61); then C62.
class DeleteAccountPage extends StatelessWidget {
  /// Creates the page.
  const DeleteAccountPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  Future<void> _deleted(BuildContext context) async {
    // Leave for the public goodbye screen first, so signing out does not
    // bounce through sign-in.
    context.go(Routes.accountDeleted);
    await signOut(services, remote: false);
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DeleteAccountCubit(ApiDeleteAccountRepository(services.api)),
    child: BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listenWhen: (_, s) => s.deleted,
      listener: (context, _) => _deleted(context),
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.accountDelete),
        body: ListView(
          padding: const EdgeInsets.all(PaoSpace.xl),
          children: [
            if (s.phone case final String phone)
              _Code(state: s, phone: phone)
            else
              _Explain(state: s),
            if (context.failureText(s.failure) case final String error)
              Padding(
                padding: const EdgeInsets.only(top: PaoSpace.md),
                child: Text(
                  error,
                  style: const TextStyle(color: PaoColors.danger),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Explain extends StatelessWidget {
  const _Explain({required this.state});

  final DeleteAccountState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: PaoColors.danger,
        ),
        const SizedBox(height: PaoSpace.lg),
        Text(
          t.accountDeleteHeading,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: PaoSpace.sm),
        Text(t.accountDeleteBody),
        const SizedBox(height: PaoSpace.sm),
        Text(
          t.accountDeleteRecords,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: PaoSpace.xxl),
        PaoButton(
          label: t.accountDeleteSendCode,
          variant: PaoButtonVariant.danger,
          loading: state.busy,
          onPressed: context.read<DeleteAccountCubit>().requestCode,
        ),
        PaoButton(
          label: context.common.actionCancel,
          variant: PaoButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class _Code extends StatelessWidget {
  const _Code({required this.state, required this.phone});

  final DeleteAccountState state;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cubit = context.read<DeleteAccountCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.accountDeleteCodeTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: PaoSpace.sm),
        Text(t.accountDeleteCodeBody(phone)),
        const SizedBox(height: PaoSpace.xl),
        PaoOtpInput(
          onCompleted: cubit.typed,
          hasError: state.failure != null,
          semanticLabel: t.accountDeleteCodeTitle,
        ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.accountDeleteConfirm,
          variant: PaoButtonVariant.danger,
          loading: state.busy,
          onPressed: state.codeComplete ? cubit.confirm : null,
        ),
        PaoButton(
          label: t.accountDeleteResend,
          variant: PaoButtonVariant.ghost,
          onPressed: state.busy ? null : cubit.requestCode,
        ),
      ],
    );
  }
}
