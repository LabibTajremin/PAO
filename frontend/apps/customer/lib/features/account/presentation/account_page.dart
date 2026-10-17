import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/presentation/log_out_sheet.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_customer/shared/photos.dart';
import 'package:pao_ui/pao_ui.dart';

/// The account tab (C22): who is signed in and the settings pages.
class AccountPage extends StatelessWidget {
  /// Creates the page.
  const AccountPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: PaoAppBar(title: context.common.navAccount),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.lg),
        children: [
          _Header(services: services),
          const SizedBox(height: PaoSpace.lg),
          const _Pages(),
          const SizedBox(height: PaoSpace.lg),
          PaoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                PaoListRow(
                  leading: const Icon(Icons.logout),
                  title: t.accountLogOut,
                  onTap: () => confirmLogOut(context, services),
                ),
                PaoListRow(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: PaoColors.danger,
                  ),
                  title: t.accountDelete,
                  onTap: () => context.push(Routes.accountPage('delete')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pages extends StatelessWidget {
  const _Pages();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pages = [
      (
        Routes.accountPage('profile'),
        Icons.person_outline,
        t.accountEditProfile,
      ),
      (
        Routes.accountPage('addresses'),
        Icons.place_outlined,
        t.accountAddresses,
      ),
      (Routes.accountPage('language'), Icons.translate, t.accountLanguage),
      (Routes.accountPage('help'), Icons.help_outline, t.accountHelp),
      (Routes.legal, Icons.policy_outlined, t.accountLegal),
    ];
    return PaoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (route, icon, title) in pages)
            PaoListRow(
              leading: Icon(icon),
              title: title,
              onTap: () => context.push(route),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: services.gate,
    builder: (context, _) {
      final profile = services.gate.profile;
      final name = profile?.name ?? '';
      final photo = profile?.photoUrl;
      final text = Theme.of(context).textTheme;
      return Row(
        children: [
          PaoAvatar(name: name, image: networkPhoto(photo), size: 64),
          const SizedBox(width: PaoSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleLarge),
                if (profile?.phone case final String phone)
                  Text(phone, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      );
    },
  );
}
