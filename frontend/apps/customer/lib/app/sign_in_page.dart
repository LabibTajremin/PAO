import 'package:flutter/material.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Placeholder sign-in (C03); the auth phase replaces it.
class SignInPage extends StatelessWidget {
  /// Creates the page.
  const SignInPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l10n = PaoL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PaoSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PAO', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: PaoSpace.xl),
              PaoLanguageSwitch(controller: services.locale),
              const Spacer(),
              PaoButton(label: l10n.actionContinue, onPressed: null),
            ],
          ),
        ),
      ),
    );
  }
}
