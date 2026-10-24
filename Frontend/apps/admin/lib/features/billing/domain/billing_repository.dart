import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Permission that opens the payments queue and merchant ledgers (ADR-0035).
const billingPermission = 'billing:manage';

/// Shortest and longest rejection reason the API accepts.
const ({int min, int max}) rejectReasonLength = (min: 3, max: 500);

/// One page of a merchant's ledger and the due it adds up to.
typedef LedgerSlice = ({DueSummary summary, Paged<LedgerEntry> entries});

/// Merchant payments and dues under cash on delivery (ADR-0035 §4).
abstract interface class BillingRepository {
  /// One page of payment submissions, only [status] ones when set.
  Future<Paged<PaymentSubmission>> payments(
    PaymentSubmissionStatus? status,
    String? cursor,
  );

  /// Confirms submission [id], crediting the merchant's ledger.
  Future<PaymentSubmission> confirm(String id);

  /// Rejects submission [id] with [reason].
  Future<PaymentSubmission> reject(String id, String reason);

  /// The due and one page of the ledger of merchant [providerId].
  Future<LedgerSlice> ledger(String providerId, String? cursor);
}
