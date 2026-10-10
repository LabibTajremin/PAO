import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/shared/paging/paged.dart';

/// A cursor-paged list: the rows so far, the next cursor and the last failure.
class PagedState<T> {
  /// Creates the state.
  const PagedState({
    this.items = const [],
    this.next,
    this.loading = false,
    this.failure,
  });

  /// Rows loaded so far.
  final List<T> items;

  /// Cursor of the next page; null when everything is loaded.
  final String? next;

  /// A page is being fetched.
  final bool loading;

  /// Why the last fetch failed.
  final AppFailure? failure;
}

/// Loads a list page by page ("load more").
class PagedCubit<T> extends Cubit<PagedState<T>> {
  /// Creates the cubit over [_fetch]; call [load] to start.
  PagedCubit(this._fetch) : super(PagedState<T>(loading: true));

  final Future<Paged<T>> Function(String? cursor) _fetch;

  /// Loads the first page again.
  Future<void> load() => _page(const [], null);

  /// Appends the next page, if there is one.
  Future<void> more() async {
    if (state.next == null || state.loading) return;
    await _page(state.items, state.next);
  }

  Future<void> _page(List<T> before, String? cursor) async {
    emit(PagedState(items: before, next: cursor, loading: true));
    try {
      final page = await _fetch(cursor);
      if (!isClosed) {
        emit(PagedState(items: [...before, ...page.items], next: page.next));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(
          PagedState(items: before, next: cursor, failure: AppFailure.from(e)),
        );
      }
    }
  }
}
