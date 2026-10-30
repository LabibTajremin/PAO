import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/settings/data/api_settings_repository.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/features/settings/presentation/admin_users_tab.dart';
import 'package:pao_admin/features/settings/presentation/audit_tab.dart';
import 'package:pao_admin/features/settings/presentation/roles_tab.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/features/settings/presentation/settings_list_tab.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Platform settings, admin users, roles and the audit log as tabs, each shown
/// only to admins holding its permission (A12, PRD A-08 and A-10).
class SettingsPage extends StatelessWidget {
  /// Creates the page on the tab at [tab] (`''`, `admins`, `roles`, `audit`).
  const SettingsPage({required this.services, this.tab = '', super.key});

  /// App services.
  final AppServices services;

  /// Path segment of the open tab.
  final String tab;

  @override
  Widget build(BuildContext context) {
    final permissions = services.permissions;
    final tabs = [
      for (final t in SettingsTab.values)
        if (permissions.can(t.permission)) t,
    ];
    if (tabs.isEmpty) return const PaoAccessDeniedView();
    final open = tabs.firstWhere((t) => t.path == tab, orElse: () => tabs[0]);
    return DefaultTabController(
      key: ValueKey(open),
      length: tabs.length,
      initialIndex: tabs.indexOf(open),
      child: ConsolePage(
        title: context.t.settingsTitle,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final t in tabs) Tab(text: t.label(context.t))],
              onTap: (i) => context.go(Routes.settingsTab(tabs[i].path)),
            ),
            Expanded(child: _body(open, ApiSettingsRepository(services.api))),
          ],
        ),
      ),
    );
  }

  Widget _body(SettingsTab open, SettingsRepository repo) => switch (open) {
    SettingsTab.settings => SettingsListTab(
      repository: repo,
      canEdit: services.permissions.can('settings:manage'),
    ),
    SettingsTab.admins => AdminUsersTab(repository: repo),
    SettingsTab.roles => RolesTab(repository: repo),
    SettingsTab.audit => AuditTab(repository: repo, now: services.now),
  };
}
