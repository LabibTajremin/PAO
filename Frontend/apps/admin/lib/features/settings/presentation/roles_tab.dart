import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/features/settings/presentation/role_dialog.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Roles with what they may do and see; edits apply to everyone holding the
/// role at once (docs/build/02-architecture.md §6).
class RolesTab extends StatelessWidget {
  /// Creates the tab.
  const RolesTab({required this.repository, super.key});

  /// Reads and changes roles.
  final SettingsRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RolesCubit(repository).loading(),
    child: BlocBuilder<RolesCubit, ViewState<RoleList>>(
      builder: (context, state) => ViewStateView<RoleList>(
        state: state,
        onRetry: context.read<RolesCubit>().load,
        isEmpty: (list) => list.items.isEmpty,
        empty: PaoEmptyState(title: context.t.rolesEmpty),
        builder: (context, list) => ListView(
          padding: const EdgeInsets.all(PaoSpace.xxl),
          children: [
            PaoBanner(
              message: context.t.rolesApplyNow,
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: PaoSpace.lg),
            for (final role in list.items)
              _RoleCard(
                role: role,
                onEdit: () => showRoleDialog(
                  context,
                  cubit: context.read<RolesCubit>(),
                  list: list,
                  role: role,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onEdit});

  final RoleDefinition role;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PaoSpace.sm,
                children: [
                  Text(
                    roleLabel(t, role.role.value),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    t.rolesCounts(
                      context.count(role.permissions.length),
                      context.count(role.screens.length),
                    ),
                  ),
                  Wrap(
                    spacing: PaoSpace.xs,
                    runSpacing: PaoSpace.xs,
                    children: [
                      for (final p in role.permissions) PaoBadge(label: p),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.rolesEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
