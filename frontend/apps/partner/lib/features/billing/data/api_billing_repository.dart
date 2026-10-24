import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/billing/domain/billing_repository.dart';

/// [BillingRepository] on the PAO API.
class ApiBillingRepository implements BillingRepository {
  /// Creates the repository.
  ApiBillingRepository(Dio api) : _api = ProviderBillingApi(api);

  final ProviderBillingApi _api;

  @override
  Future<DueSummary> due() async => (await _api.getMyDue()).data!;

  @override
  Future<Paged<LedgerEntry>> ledger({String? cursor}) async {
    final page = (await _api.listMyLedger(cursor: cursor)).data!;
    return Paged(page.items, page.nextCursor);
  }

  @override
  Future<Paged<PaymentSubmission>> payments({String? cursor}) async {
    final page = (await _api.listMyPayments(cursor: cursor)).data!;
    return Paged(page.items, page.nextCursor);
  }

  @override
  Future<PaymentSubmission> submit(PaymentSubmissionInput input) async =>
      (await _api.submitPayment(paymentSubmissionInput: input)).data!;
}
