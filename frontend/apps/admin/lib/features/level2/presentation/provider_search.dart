import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Searches providers by name or phone; null before the first search.
class ProviderSearchCubit
    extends Cubit<ViewState<List<AdminProviderSummary>>?> {
  /// Creates the cubit; [level] keeps only providers at that level.
  ProviderSearchCubit(this._repo, {this.level}) : super(null);

  final Level2Repository _repo;

  /// Level the results must have, or null for any.
  final int? level;

  /// Runs a search for [query]; blank queries are ignored.
  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    emit(const ViewLoading());
    try {
      final found = await _repo.providers(query, level: level);
      if (!isClosed) emit(ViewData(found));
    } on Object catch (e) {
      if (!isClosed) emit(ViewFailure(AppFailure.from(e)));
    }
  }
}

/// A search box with matching providers below; tapping one picks it.
class ProviderSearch extends StatefulWidget {
  /// Creates the search over the nearest [ProviderSearchCubit].
  const ProviderSearch({required this.onPick, super.key});

  /// Called with the chosen provider.
  final ValueChanged<AdminProviderSummary> onPick;

  @override
  State<ProviderSearch> createState() => _ProviderSearchState();
}

class _ProviderSearchState extends State<ProviderSearch> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProviderSearchCubit>();
    final state = cubit.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _query,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: context.t.level2FindProvider,
            hintText: context.t.level2FindHint,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: cubit.search,
        ),
        if (state != null)
          SizedBox(
            height: 220,
            child: ViewStateView<List<AdminProviderSummary>>(
              state: state,
              onRetry: () => cubit.search(_query.text),
              isEmpty: (list) => list.isEmpty,
              empty: PaoEmptyState(title: context.t.level2NoProviders),
              builder: (_, list) =>
                  ListView(children: [for (final p in list) _tile(context, p)]),
            ),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, AdminProviderSummary p) => ListTile(
    leading: PaoAvatar(name: p.name, size: 36),
    title: Text(p.name),
    subtitle: Text(
      [p.phone, levelLabel(context.t, p.level)].nonNulls.join(' · '),
    ),
    onTap: () => widget.onPick(p),
  );
}
