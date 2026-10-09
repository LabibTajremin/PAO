import 'package:flutter/material.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Placeholder home (A02) until the feature phases build the real one.
class HomePage extends StatelessWidget {
  /// Creates the page.
  const HomePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l10n = PaoL10n.of(context);
    return Scaffold(
      appBar: PaoAppBar(title: l10n.appName),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.lg),
        children: [
          PaoLanguageSwitch(controller: services.locale),
          const SizedBox(height: PaoSpace.xl),
          PaoButton(
            label: l10n.actionSignOut,
            variant: PaoButtonVariant.outline,
            onPressed: () async {
              services.permissions.clear();
              await services.sessions.signOut();
            },
          ),
        ],
      ),
    );
  }
}
