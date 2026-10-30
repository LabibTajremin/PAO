import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/billing/domain/billing_repository.dart';
import 'package:pao_partner/features/billing/presentation/pay_cubit.dart';

class _Repo implements BillingRepository {
  PaymentSubmissionInput? sent;
  Exception? error;

  @override
  Future<PaymentSubmission> submit(PaymentSubmissionInput input) async {
    if (error case final e?) throw e;
    sent = input;
    return PaymentSubmission(
      id: 'p1',
      providerId: 'm1',
      amount: input.amountPaisa,
      method: input.method,
      reference: input.reference,
      status: PaymentSubmissionStatus.pending,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<DueSummary> due() => throw UnimplementedError();

  @override
  Future<Paged<LedgerEntry>> ledger({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<Paged<PaymentSubmission>> payments({String? cursor}) =>
      throw UnimplementedError();
}

DueSummary _due(int due, {int limit = 50000, bool? blocked}) => DueSummary(
  due: due,
  blockAmount: limit,
  blocked: blocked ?? due > limit,
  commissionRateBp: 1000,
  pendingPayments: 0,
);

void main() {
  test('amounts in taka become paisa within the API limits', () {
    expect(parsePaisa('500'), 50000);
    expect(parsePaisa(' 499.5 '), 49950);
    expect(parsePaisa('0.01'), 1);
    expect(parsePaisa('1000000'), maxPaymentPaisa);
    for (final bad in ['', '0', '0.00', '1000000.01', '1.234', 'abc', '-5']) {
      expect(parsePaisa(bad), isNull, reason: bad);
    }
  });

  test('the home screen warns when blocked or at 80% of the limit', () {
    expect(dueNeedsAttention(_due(60000)), isTrue);
    expect(dueNeedsAttention(_due(40000)), isTrue);
    expect(dueNeedsAttention(_due(39999)), isFalse);
    expect(dueNeedsAttention(_due(0, limit: 0)), isFalse);
    expect(dueNeedsAttention(_due(10, limit: 0, blocked: true)), isTrue);
  });

  test('every field is checked before sending', () async {
    final repo = _Repo();
    final cubit = PayCubit(repo);
    await cubit.submit('x', ' ');
    expect(cubit.state.badAmount, isTrue);
    expect(cubit.state.missingMethod, isTrue);
    expect(cubit.state.badReference, isTrue);
    cubit.choose(PaymentMethodKind.nagad);
    await cubit.submit('200', 'r' * 121);
    expect(cubit.state.badAmount, isFalse);
    expect(cubit.state.missingMethod, isFalse);
    expect(cubit.state.badReference, isTrue);
    expect(repo.sent, isNull);
  });

  test('a valid payment is sent; a failure is kept', () async {
    final repo = _Repo()..error = const NetworkFailure();
    final cubit = PayCubit(repo)..choose(PaymentMethodKind.bkash);
    await cubit.submit('200.50', ' TX9 ');
    expect(cubit.state.failure, isA<NetworkFailure>());
    expect(cubit.state.sent, isFalse);
    repo.error = null;
    await cubit.submit('200.50', ' TX9 ');
    expect(cubit.state.sent, isTrue);
    expect(cubit.state.method, PaymentMethodKind.bkash);
    expect(repo.sent!.amountPaisa, 20050);
    expect(repo.sent!.reference, 'TX9');
  });
}
