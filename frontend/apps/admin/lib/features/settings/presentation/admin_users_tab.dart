import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/features/settings/presentation/admin_user_dialog.dart';
import 'package:pao_admin/features/settings/presentation/invite_dialog.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Admin users with their roles, 2FA and status; invite, change roles or
/// deactivate (A-01).
class AdminUsersTab extends StatelessWidget {
  /// Creates the tab.
  const AdminUsersTab({required this.repository, super.key});

  /// Reads and changes admin users.
  final SettingsRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AdminUsersCubit(repository).loading(),
    child: BlocBuilder<AdminUsersCubit, ViewState<List<AdminUser>>>(
      builder: (context, state) {
        final cubit = context.read<AdminUsersCubit>();
        return ListView(
          padding: const EdgeInsets.all(PaoSpace.xxl),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: PaoButton(
                label: context.t.adminsInvite,
                icon: Icons.person_add_alt,
                expand: false,
                onPressed: () => showInviteDialog(context, cubit: cubit),
              ),
            ),
            const SizedBox(height: PaoSpace.lg),
            ViewStateView<List<AdminUser>>(
              state: state,
              onRetry: cubit.load,
              isEmpty: (users) => users.isEmpty,
              empty: PaoEmptyState(title: context.t.adminsEmpty),
              builder: (context, users) => Column(
                spacing: PaoSpace.md,
                children: [
                  for (final u in users) _AdminCard(user: u, cubit: cubit),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.user, required this.cubit});

  final AdminUser user;
  final AdminUsersCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final seen = user.lastLoginAt;
    return PaoCard(
      child: Row(
        spacing: PaoSpace.md,
        children: [
          PaoAvatar(name: user.name, size: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PaoSpace.xs,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                Text(user.email),
                Text(
                  seen == null
                      ? t.adminsNeverSignedIn
                      : t.adminsLastSignIn(context.when(seen)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Wrap(
                  spacing: PaoSpace.xs,
                  runSpacing: PaoSpace.xs,
                  children: _badges(t),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.adminsEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                showAdminUserDialog(context, cubit: cubit, user: user),
          ),
        ],
      ),
    );
  }

  List<Widget> _badges(AdminL10n t) => [
    for (final r in user.roles) PaoBadge(label: roleLabel(t, r.value)),
    if (user.active)
      PaoBadge(label: t.adminsActive, tone: PaoTone.success)
    else
      PaoBadge(label: t.adminsInactive, tone: PaoTone.danger),
    if (user.totpEnrolled)
      PaoBadge(label: t.adminsTotpOn, tone: PaoTone.accent)
    else
      PaoBadge(label: t.adminsTotpOff, tone: PaoTone.warning),
  ];
}
