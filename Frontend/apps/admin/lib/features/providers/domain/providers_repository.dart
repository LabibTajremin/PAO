import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the providers list (A08) is narrowed to.
class ProviderFilter {
  /// Creates the filter; the defaults show every provider.
  const ProviderFilter({
    this.query,
    this.status,
    this.level,
    this.flagged = false,
  });

  /// Name or phone.
  final String? query;

  /// Account status.
  final AccountStatus? status;

  /// Verification level, 0–2.
  final int? level;

  /// Only providers flagged for review (PRD §6.4 quality thresholds).
  final bool flagged;

  /// This filter searching for [text]; blank clears the search.
  ProviderFilter searching(String text) => ProviderFilter(
    query: text.trim().isEmpty ? null : text.trim(),
    status: status,
    level: level,
    flagged: flagged,
  );

  /// This filter with [status] instead.
  ProviderFilter withStatus(AccountStatus? status) => ProviderFilter(
    query: query,
    status: status,
    level: level,
    flagged: flagged,
  );

  /// This filter with [level] instead.
  ProviderFilter withLevel(int? level) => ProviderFilter(
    query: query,
    status: status,
    level: level,
    flagged: flagged,
  );

  /// This filter with the flagged-only switch turned over.
  ProviderFilter toggleFlagged() => ProviderFilter(
    query: query,
    status: status,
    level: level,
    flagged: !flagged,
  );
}

/// Provider management for admins (A-05).
abstract interface class ProvidersRepository {
  /// One page of providers matching [filter].
  Future<Paged<AdminProviderSummary>> list(
    ProviderFilter filter,
    String? cursor,
  );

  /// A provider with verification, bookings and status history.
  Future<AdminProviderDetail> detail(String id);

  /// Suspends, bans or reinstates provider [id]; a ban also blocks the NID,
  /// phone and face from registering again.
  Future<AdminProviderDetail> changeStatus(
    String id,
    AccountStatusChange change,
  );
}
