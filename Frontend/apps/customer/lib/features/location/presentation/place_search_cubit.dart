import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_customer/features/location/domain/places.dart';
import 'package:pao_customer/shared/debouncer.dart';

/// Address suggestions for what the customer types (C06).
class PlaceSearchCubit extends Cubit<List<Place>> {
  /// Creates the cubit; [language] is `en` or `bn`.
  PlaceSearchCubit(
    this._places, {
    this.language = 'en',
    Duration delay = const Duration(milliseconds: 300),
  }) : _debounce = Debouncer(delay),
       super(const []);

  final PlacesService _places;
  final Debouncer _debounce;

  /// Language of the suggestions.
  final String language;

  /// Searches [text] after a pause in typing; short text clears the list.
  void query(String text) {
    final q = text.trim();
    if (q.length < 3) {
      _debounce.cancel();
      return emit(const []);
    }
    _debounce.run(() => _search(q));
  }

  /// Hides the suggestions.
  void clear() {
    _debounce.cancel();
    emit(const []);
  }

  Future<void> _search(String q) async {
    List<Place> found;
    try {
      found = await _places.search(q, language: language);
    } on Object {
      // Search is a shortcut: when it fails the customer types the address.
      found = const [];
    }
    if (!isClosed) emit(found);
  }

  @override
  Future<void> close() {
    _debounce.cancel();
    return super.close();
  }
}
