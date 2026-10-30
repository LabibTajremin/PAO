import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart' show DueSummary;
import 'package:pao_partner/features/billing/presentation/billing_labels.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The due, the block limit, the rate and payments awaiting confirmation.
class DueSummaryCard extends StatelessWidget {
  /// Creates the card for [due].
  const DueSummaryCard({required this.due, super.key});

  /// The loaded summary.
  final DueSummary due;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return PaoCard(
      highlighted: due.blocked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.billDue),
          PaoMoneyText(
            due.due,
            style: text.headlineSmall?.copyWith(
              color: due.blocked ? PaoColors.danger : null,
            ),
          ),
          Text(t.billLimit(context.money(due.blockAmount))),
          Text(t.billRate(context.percent(due.commissionRateBp))),
          if (due.pendingPayments > 0)
            Text(t.billPendingTotal(context.money(due.pendingPayments))),
          if (due.blocked) ...[
            const SizedBox(height: PaoSpace.sm),
            Text(
              t.billBlockedBody,
              style: const TextStyle(color: PaoColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
