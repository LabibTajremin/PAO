import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/providers/domain/providers_repository.dart';
import 'package:pao_customer/shared/booking_draft.dart';

/// The nearby search behind the list: the API sorts, the app filters.
class _Nearby {
  _Nearby(this.repo, this.draft, this.addressId);

  final ProvidersRepository repo;
  final BookingDraft draft;
  final String addressId;
  ProviderQuery query = const ProviderQuery();
  PriceSummary? summary;

  /// Skips pages the filters empty, so the list never shows "no providers"
  /// while more pages remain.
  Future<Paged<ProviderCard>> page(String? cursor) async {
    var next = cursor;
    while (true) {
      final page = await repo.nearby(
        draft: draft,
        addressId: addressId,
        sort: query.sort,
        cursor: next,
      );
      summary = page.summary;
      final kept = page.items.where(query.keeps).toList();
      next = page.next;
      if (kept.isNotEmpty || next == null) return Paged(kept, next);
    }
  }
}

/// Providers near the customer's address (C10, C39, C40).
class ProvidersCubit extends PagedCubit<ProviderCard> {
  /// Creates the cubit for [draft] around [addressId]; call [load] to start.
  ProvidersCubit(
    ProvidersRepository repo, {
    required BookingDraft draft,
    required String addressId,
  }) : this._(_Nearby(repo, draft, addressId));

  ProvidersCubit._(this._nearby) : super(_nearby.page);

  final _Nearby _nearby;

  /// The current sort and filters.
  ProviderQuery get query => _nearby.query;

  /// The price of the selection, once a page has loaded.
  PriceSummary? get summary => _nearby.summary;

  /// Applies [query] and reloads the list.
  Future<void> apply(ProviderQuery query) {
    _nearby.query = query;
    return load();
  }
}
