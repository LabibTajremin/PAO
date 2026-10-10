import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/auth/data/api_auth_repository.dart';
import 'package:pao_customer/features/auth/data/start_session.dart';
import 'package:pao_customer/features/auth/presentation/otp_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Code entry with resend timer and wrong-code state (C04, C33).
class OtpPage extends StatelessWidget {
  /// Creates the page for [phone].
  const OtpPage({required this.services, required this.phone, super.key});

  /// App services.
  final AppServices services;

  /// Number the code went to.
  final String phone;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OtpCubit(
      ApiAuthRepository(services.api),
      phone,
      onSignedIn: (tokens) => startSession(services, tokens),
    ),
    child: BlocConsumer<OtpCubit, OtpState>(
      listenWhen: (_, s) => s.done,
      listener: (context, _) => context.go(Routes.home),
      builder: _content,
    ),
  );

  Widget _content(BuildContext context, OtpState s) {
    final cubit = context.read<OtpCubit>();
    return Scaffold(
      appBar: PaoAppBar(title: context.t.authOtpTitle),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          Text(context.t.authOtpSentTo(phone)),
          const SizedBox(height: PaoSpace.xxl),
          PaoOtpInput(onCompleted: cubit.verify, hasError: s.wrongCode),
          if (s.failure != null) ...[
            const SizedBox(height: PaoSpace.md),
            Text(
              context.failureText(s.failure)!,
              style: const TextStyle(color: PaoColors.danger),
            ),
          ],
          const SizedBox(height: PaoSpace.xl),
          if (s.verifying) const Center(child: CircularProgressIndicator()),
          PaoButton(
            label: s.resendIn > 0
                ? context.t.authResendIn(s.resendIn)
                : context.t.authResend,
            variant: PaoButtonVariant.ghost,
            onPressed: s.resendIn > 0 ? null : cubit.resend,
          ),
        ],
      ),
    );
  }
}
