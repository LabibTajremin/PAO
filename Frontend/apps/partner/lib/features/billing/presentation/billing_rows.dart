import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/billing/presentation/billing_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One ledger entry: a commission debit or a confirmed payment credit.
class LedgerRow extends StatelessWidget {
  /// Creates the row.
  const LedgerRow({required this.entry, super.key});

  /// The entry.
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final debit = entry.kind == LedgerEntryKindEnum.commission;
    final total = entry.jobTotal;
    return PaoListRow(
      leading: Icon(debit ? Icons.remove_circle_outline : Icons.add_circle),
      title: debit ? t.billCommission(entry.bookingNumber ?? '') : t.billCredit,
      subtitle: [
        context.when(entry.createdAt),
        if (total != null) t.billJobTotal(context.money(total)),
      ].join(' · '),
      trailing: Text(
        '${debit ? '+' : '−'}${context.money(entry.amount)}',
        style: TextStyle(color: debit ? PaoColors.danger : null),
      ),
    );
  }
}

/// One reported payment and what the admin decided.
class PaymentRow extends StatelessWidget {
  /// Creates the row.
  const PaymentRow({required this.payment, super.key});

  /// The submission.
  final PaymentSubmission payment;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final reason = payment.reason;
    return PaoListRow(
      title:
          '${paymentMethods(t)[payment.method]} · '
          '${paymentStatusText(t, payment.status)}',
      subtitle: [
        payment.reference,
        context.when(payment.createdAt),
        if (reason != null) t.billRejectedReason(reason),
      ].join(' · '),
      trailing: PaoMoneyText(payment.amount),
    );
  }
}
