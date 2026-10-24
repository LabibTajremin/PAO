import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The merchant's dues to PAO under cash on delivery (ADR-0035).
abstract interface class BillingRepository {
  /// The due against the block limit.
  Future<DueSummary> due();

  /// Commission debits and payment credits, newest first.
  Future<Paged<LedgerEntry>> ledger({String? cursor});

  /// Payments the merchant reported, newest first.
  Future<Paged<PaymentSubmission>> payments({String? cursor});

  /// Reports a payment for an admin to confirm.
  Future<PaymentSubmission> submit(PaymentSubmissionInput input);
}

/// Share of the limit at which the home screen starts warning.
const nearLimitShare = 0.8;

/// Whether [due] should be brought to the merchant's attention.
bool dueNeedsAttention(DueSummary due) =>
    due.blocked ||
    (due.blockAmount > 0 && due.due >= due.blockAmount * nearLimitShare);
