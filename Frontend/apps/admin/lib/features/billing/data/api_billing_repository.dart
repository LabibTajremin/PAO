import 'package:dio/dio.dart';
import 'package:pao_admin/features/billing/domain/billing_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [BillingRepository] on the PAO API.
class ApiBillingRepository implements BillingRepository {
  /// Creates the repository.
  ApiBillingRepository(Dio api) : _api = AdminBillingApi(api);

  final AdminBillingApi _api;

  @override
  Future<Paged<PaymentSubmission>> payments(
    PaymentSubmissionStatus? status,
    String? cursor,
  ) async {
    final page = (await _api.listPaymentSubmissions(
      status: status,
      cursor: cursor,
    )).data!;
    return Paged(page.items, page.nextCursor);
  }

  @override
  Future<PaymentSubmission> confirm(String id) async =>
      (await _api.confirmPayment(submissionId: id)).data!;

  @override
  Future<PaymentSubmission> reject(String id, String reason) async =>
      (await _api.rejectPayment(
        submissionId: id,
        paymentRejectInput: PaymentRejectInput(reason: reason),
      )).data!;

  @override
  Future<LedgerSlice> ledger(String providerId, String? cursor) async {
    final page = (await _api.getMerchantLedger(
      providerId: providerId,
      cursor: cursor,
    )).data!;
    return (
      summary: page.summary,
      entries: Paged(page.entries.items, page.entries.nextCursor),
    );
  }
}
