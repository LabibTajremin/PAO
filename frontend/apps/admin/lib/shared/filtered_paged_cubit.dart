import 'package:pao_core/pao_core.dart';

/// Fetches the page after [cursor] of the rows matching [filter].
typedef FilteredFetch<T, F> = Future<Paged<T>> Function(
  F filter,
  String? cursor,
);

/// A [PagedCubit] over rows that match a filter the admin changes: [apply]
/// restarts from the first page, [refresh] reloads it in place.
class FilteredPagedCubit<T, F> extends PagedCubit<T> {
  /// Creates the cubit, showing rows that match [initial]; call `load`.
  factory FilteredPagedCubit(F initial, FilteredFetch<T, F> fetch) =>
      FilteredPagedCubit._(_Box(initial), fetch);

  FilteredPagedCubit._(this._filter, this._fetch)
    : super((cursor) => _fetch(_filter.value, cursor));

  final _Box<F> _filter;
  final FilteredFetch<T, F> _fetch;

  /// What the rows match.
  F get filter => _filter.value;

  /// Shows the rows matching [filter] from the first page.
  Future<void> apply(F filter) {
    _filter.value = filter;
    return load();
  }

  /// Reloads the first page without the loading state, e.g. on a timer.
  Future<void> refresh() async {
    if (state.loading) return;
    final asked = filter;
    try {
      final page = await _fetch(asked, null);
      // A filter applied meanwhile owns the rows now.
      if (isClosed || !identical(asked, filter) || state.loading) return;
      emit(PagedState(items: page.items, next: page.next));
    } on Object {
      // The rows on screen stay readable; the next tick tries again.
    }
  }
}

class _Box<F> {
  _Box(this.value);

  F value;
}
