import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/auth/data/api_auth_repository.dart';
import 'package:pao_customer/features/auth/presentation/phone_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Phone entry (C03).
class PhonePage extends StatefulWidget {
  /// Creates the page.
  const PhonePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PhoneCubit(ApiAuthRepository(widget.services.api)),
    child: BlocConsumer<PhoneCubit, PhoneState>(
      listenWhen: (_, s) => s.sentTo != null,
      listener: (context, s) => context.go(
        Uri(path: Routes.otp, queryParameters: {'phone': s.sentTo}).toString(),
      ),
      builder: _form,
    ),
  );

  Widget _form(BuildContext context, PhoneState s) {
    final services = widget.services;
    return ValueListenableBuilder<AppLook>(
      valueListenable: services.look.look,
      builder: (context, look, _) => PaoSignInLayout(
        hero: LookArtwork(services.look.look, 'customer.signin.hero'),
        tagline: look.tagline(Localizations.localeOf(context).languageCode),
        title: context.t.authWelcome,
        subtitle: context.t.authPhoneBody,
        children: [
          PaoTextField(
            label: context.t.authPhoneLabel,
            controller: _phone,
            prefix: '+880',
            hint: '1XXXXXXXXX',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            error: s.invalid
                ? context.t.authPhoneInvalid
                : context.failureText(s.failure),
          ),
          const SizedBox(height: PaoSpace.xl),
          PaoButton(
            label: context.t.authSendOtp,
            loading: s.sending,
            onPressed: () => context.read<PhoneCubit>().submit(_phone.text),
          ),
          const SizedBox(height: PaoSpace.lg),
          Text(
            context.t.authTermsNote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: () => context.push(Routes.legal),
            child: Text(context.t.authTermsLink),
          ),
        ],
      ),
    );
  }
}
