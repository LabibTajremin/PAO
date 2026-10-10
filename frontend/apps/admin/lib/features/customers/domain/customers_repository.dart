import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the customers list (A09) is narrowed to.
class CustomerFilter {
  /// Creates the filter; the defaults show every customer.
  const CustomerFilter({this.query, this.status});

  /// Name or phone.
  final String? query;

  /// Account status.
  final AccountStatus? status;

  /// This filter searching for [text]; blank clears the search.
  CustomerFilter searching(String text) => CustomerFilter(
    query: text.trim().isEmpty ? null : text.trim(),
    status: status,
  );

  /// This filter with [status] instead.
  CustomerFilter withStatus(AccountStatus? status) =>
      CustomerFilter(query: query, status: status);
}

/// Customer management for admins (A-05).
abstract interface class CustomersRepository {
  /// One page of customers matching [filter].
  Future<Paged<AdminCustomerSummary>> list(
    CustomerFilter filter,
    String? cursor,
  );

  /// A customer with bookings, complaints and status history.
  Future<AdminCustomerDetail> detail(String id);

  /// Suspends, bans or reinstates customer [id].
  Future<AdminCustomerDetail> changeStatus(
    String id,
    AccountStatusChange change,
  );
}
