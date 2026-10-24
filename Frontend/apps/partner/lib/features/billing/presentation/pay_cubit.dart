import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/billing/domain/billing_repository.dart';

/// The largest payment the API takes, in paisa (৳10,00,000).
const maxPaymentPaisa = 100000000;

/// The longest reference the API takes.
const maxReferenceLength = 120;

/// Taka typed by the merchant, e.g. `500` or `499.50`, as paisa; null when it
/// is not a positive amount with at most two decimals within the limit.
int? parsePaisa(String text) {
  final match = RegExp(r'^(\d{1,7})(?:\.(\d{1,2}))?$').firstMatch(text.trim());
  if (match == null) return null;
  final cents = (match.group(2) ?? '').padRight(2, '0');
  final paisa = int.parse(match.group(1)!) * 100 + int.parse(cents);
  return paisa < 1 || paisa > maxPaymentPaisa ? null : paisa;
}

/// The pay form: the chosen method, field errors and the submission.
class PayState {
  /// Creates the state.
  const PayState({
    this.method,
    this.badAmount = false,
    this.missingMethod = false,
    this.badReference = false,
    this.sending = false,
    this.failure,
    this.sent = false,
  });

  /// How the merchant paid.
  final PaymentMethodKind? method;

  /// The amount is not valid.
  final bool badAmount;

  /// No method was chosen.
  final bool missingMethod;

  /// The reference is empty or too long.
  final bool badReference;

  /// The payment is being reported.
  final bool sending;

  /// Why reporting failed.
  final AppFailure? failure;

  /// The payment was reported.
  final bool sent;
}

/// Validates and reports a payment of the due (ADR-0035 §4).
class PayCubit extends Cubit<PayState> {
  /// Creates the cubit.
  PayCubit(this._repo) : super(const PayState());

  final BillingRepository _repo;

  /// Chooses how the merchant paid.
  void choose(PaymentMethodKind method) => emit(PayState(method: method));

  /// Checks the fields, then reports the payment.
  Future<void> submit(String amount, String reference) async {
    final paisa = parsePaisa(amount);
    final ref = reference.trim();
    final method = state.method;
    final badRef = ref.isEmpty || ref.length > maxReferenceLength;
    if (paisa == null || method == null || badRef) {
      return emit(
        PayState(
          method: method,
          badAmount: paisa == null,
          missingMethod: method == null,
          badReference: badRef,
        ),
      );
    }
    emit(PayState(method: method, sending: true));
    final failure = await attempt(
      () => _repo.submit(
        PaymentSubmissionInput(
          amountPaisa: paisa,
          method: method,
          reference: ref,
        ),
      ),
    );
    emit(PayState(method: method, failure: failure, sent: failure == null));
  }
}
