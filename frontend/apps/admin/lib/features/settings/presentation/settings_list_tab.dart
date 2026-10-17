import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/features/settings/presentation/setting_dialog.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/features/settings/presentation/settings_labels.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Platform settings such as timeouts, rating thresholds and cancellation
/// rules (A-10), searchable by key or description.
class SettingsListTab extends StatefulWidget {
  /// Creates the tab; [canEdit] shows the edit buttons.
  const SettingsListTab({
    required this.repository,
    required this.canEdit,
    super.key,
  });

  /// Reads and changes settings.
  final SettingsRepository repository;

  /// The admin holds `settings:manage`.
  final bool canEdit;

  @override
  State<SettingsListTab> createState() => _SettingsListTabState();
}

class _SettingsListTabState extends State<SettingsListTab> {
  var _query = '';

  bool _matches(Setting s) {
    final q = _query.trim().toLowerCase();
    return s.key.contains(q) || s.description.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsCubit(widget.repository).loading(),
    child: BlocBuilder<SettingsCubit, ViewState<List<Setting>>>(
      builder: (context, state) => ViewStateView<List<Setting>>(
        state: state,
        onRetry: context.read<SettingsCubit>().load,
        isEmpty: (items) => items.isEmpty,
        empty: PaoEmptyState(title: context.t.settingsEmpty),
        builder: (context, items) => ListView(
          padding: const EdgeInsets.all(PaoSpace.xxl),
          children: [
            FilterBar(
              search: (q) => setState(() => _query = q),
              searchHint: context.t.settingsSearch,
            ),
            for (final s in items.where(_matches))
              _SettingRow(
                setting: s,
                onEdit: widget.canEdit ? () => _edit(context, s) : null,
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _edit(BuildContext context, Setting setting) async {
    final saved = await showSettingDialog(
      context,
      cubit: context.read<SettingsCubit>(),
      setting: setting,
    );
    if ((saved ?? false) && context.mounted) {
      showDone(context, context.t.formSaved);
    }
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.setting, this.onEdit});

  final Setting setting;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final at = setting.updatedAt;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(setting.key, style: const TextStyle(fontFamily: 'monospace')),
      subtitle: Text(
        [
          setting.description,
          if (at != null) context.t.settingsUpdatedAt(context.when(at)),
        ].join('\n'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            settingValue(context.t, setting),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (onEdit != null)
            IconButton(
              tooltip: context.t.settingsEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
