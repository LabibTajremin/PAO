import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/search/domain/search_repository.dart';
import 'package:pao_customer/shared/debouncer.dart';

/// Search results (C08, C38).
class SearchState {
  /// Creates the state.
  const SearchState({
    this.query = '',
    this.results,
    this.loading = false,
    this.failure,
  });

  /// The trimmed text searched for.
  final String query;

  /// The last results, if any.
  final CatalogSearchResults? results;

  /// A search is on its way.
  final bool loading;

  /// Why the last search failed.
  final AppFailure? failure;

  /// Whether the last search found nothing (C38).
  bool get nothingFound =>
      results != null &&
      results!.services.isEmpty &&
      results!.subServices.isEmpty;
}

/// Searches as the customer types, once per pause.
class SearchCubit extends Cubit<SearchState> {
  /// Creates the cubit; [delay] is the typing pause.
  SearchCubit(this._repo, {Duration delay = const Duration(milliseconds: 300)})
    : _debounce = Debouncer(delay),
      super(const SearchState());

  final SearchRepository _repo;
  final Debouncer _debounce;

  /// Searches [text] after a pause; empty text clears the results.
  void query(String text) {
    final q = text.trim();
    if (q.isEmpty) {
      _debounce.cancel();
      return emit(const SearchState());
    }
    emit(SearchState(query: q, results: state.results, loading: true));
    _debounce.run(() => _search(q));
  }

  /// Runs the last search again.
  Future<void> retry() {
    emit(SearchState(query: state.query, loading: true));
    return _search(state.query);
  }

  Future<void> _search(String q) async {
    try {
      final found = await _repo.search(q);
      // A slower answer to an older query must not replace a newer one.
      if (!isClosed && q == state.query) {
        emit(SearchState(query: q, results: found));
      }
    } on Object catch (e) {
      if (!isClosed && q == state.query) {
        emit(SearchState(query: q, failure: AppFailure.from(e)));
      }
    }
  }

  @override
  Future<void> close() {
    _debounce.cancel();
    return super.close();
  }
}
