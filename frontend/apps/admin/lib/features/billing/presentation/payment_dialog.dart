import 'package:flutter/material.dart';
import 'package:pao_admin/features/billing/presentation/billing_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';

/// What the admin chose to do with a submission.
enum PaymentAction {
  /// Credit the ledger.
  confirm,

  /// Refuse it with a reason.
  reject,

  /// Open the merchant's ledger.
  ledger,
}

/// Shows [payment] with the actions it allows; resolves with the choice.
Future<PaymentAction?> showPaymentDialog(
  BuildContext context,
  PaymentSubmission payment,
) => showDialog<PaymentAction>(
  context: context,
  builder: (context) => _PaymentDialog(payment: payment),
);

class _PaymentDialog extends StatelessWidget {
  const _PaymentDialog({required this.payment});

  final PaymentSubmission payment;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = payment;
    final reviewed = p.reviewedAt;
    final reason = p.reason;
    return AlertDialog(
      title: Text(context.money(p.amount)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusCell(
              label: paymentStatusLabel(t, p.status),
              tone: paymentStatusTone(p.status),
            ),
            Fact(t.payMerchant, p.providerId),
            Fact(t.payMethod, paymentMethodLabel(t, p.method)),
            Fact(t.payReference, p.reference),
            Fact(t.paySubmitted, context.when(p.createdAt)),
            if (reviewed != null) Fact(t.payReviewed, context.when(reviewed)),
            if (reason != null) Fact(t.payReason, reason),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, PaymentAction.ledger),
          child: Text(t.payViewLedger),
        ),
        if (p.status == PaymentSubmissionStatus.pending) ...[
          OutlinedButton(
            onPressed: () => Navigator.pop(context, PaymentAction.reject),
            child: Text(t.payReject),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, PaymentAction.confirm),
            child: Text(t.payConfirm),
          ),
        ],
      ],
    );
  }
}
