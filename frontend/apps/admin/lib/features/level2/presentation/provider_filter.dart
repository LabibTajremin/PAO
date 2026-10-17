import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/level2/presentation/provider_search.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';

/// A filter chip for one provider: tapping it searches for a provider, the
/// clear icon shows every provider again.
class ProviderFilter extends StatelessWidget {
  /// Creates the filter.
  const ProviderFilter({
    required this.repo,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Where providers are searched.
  final Level2Repository repo;

  /// The chosen provider, or null for all.
  final AdminProviderSummary? selected;

  /// Called with the new choice.
  final ValueChanged<AdminProviderSummary?> onChanged;

  Future<void> _choose(BuildContext context) async {
    final picked = await showDialog<AdminProviderSummary>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.level2FilterProvider),
        content: SizedBox(
          width: 420,
          child: BlocProvider(
            create: (_) => ProviderSearchCubit(repo),
            child: ProviderSearch(onPick: (p) => Navigator.pop(context, p)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.common.actionCancel),
          ),
        ],
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final name = selected?.name ?? t.level2AnyProvider;
    return InputChip(
      avatar: const Icon(Icons.person_search, size: 18),
      label: Text('${t.level2FilterProvider}: $name'),
      onPressed: () => _choose(context),
      onDeleted: selected == null ? null : () => onChanged(null),
    );
  }
}
