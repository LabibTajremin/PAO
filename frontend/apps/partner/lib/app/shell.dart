import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The tab scaffold: Home, Jobs, Earnings, Profile.
class PartnerShell extends StatelessWidget {
  /// Creates the shell around the active [shell] branch.
  const PartnerShell({required this.shell, super.key});

  /// The tab navigator.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = PaoL10n.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: PaoBottomNav(
        index: shell.currentIndex,
        onSelected: (i) => shell.goBranch(i, initialLocation: true),
        items: [
          PaoNavItem(icon: Icons.home_outlined, label: l10n.navHome),
          PaoNavItem(icon: Icons.work_outline, label: l10n.navJobs),
          PaoNavItem(icon: Icons.payments_outlined, label: l10n.navEarnings),
          PaoNavItem(icon: Icons.person_outline, label: l10n.navAccount),
        ],
      ),
    );
  }
}
