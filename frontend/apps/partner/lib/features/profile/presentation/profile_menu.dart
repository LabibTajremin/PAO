import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/data/sign_out.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Links to the profile sub-pages (M29–M35) and log out (M36).
class ProfileMenu extends StatelessWidget {
  /// Creates the menu.
  const ProfileMenu({required this.services, super.key});

  /// App services.
  final AppServices services;

  Future<void> _logOut(BuildContext context) async {
    final t = context.t;
    final confirmed = await showPaoSheet<bool>(
      context,
      title: t.profLogOutTitle,
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.profLogOutBody),
            const SizedBox(height: PaoSpace.xl),
            PaoButton(
              label: t.profLogOut,
              variant: PaoButtonVariant.danger,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
            PaoButton(
              label: sheet.common.actionCancel,
              variant: PaoButtonVariant.ghost,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
          ],
        ),
      ),
    );
    if (confirmed ?? false) await signOut(services);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pages = {
      'public': (Icons.visibility_outlined, t.profPublicTitle),
      'reviews': (Icons.star_outline, t.profReviewsTitle),
      'documents': (Icons.description_outlined, t.profDocumentsTitle),
      'level': (Icons.verified_outlined, t.profLevelTitle),
      'services': (Icons.home_repair_service_outlined, t.profServicesTitle),
      'language': (Icons.translate, t.profLanguageTitle),
      'help': (Icons.help_outline, t.profHelpTitle),
    };
    return PaoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final MapEntry(key: page, value: (icon, title)) in pages.entries)
            PaoListRow(
              leading: Icon(icon),
              title: title,
              onTap: () => context.push(Routes.profilePage(page)),
            ),
          PaoListRow(
            leading: const Icon(Icons.logout, color: PaoColors.danger),
            title: t.profLogOut,
            onTap: () => _logOut(context),
          ),
        ],
      ),
    );
  }
}
