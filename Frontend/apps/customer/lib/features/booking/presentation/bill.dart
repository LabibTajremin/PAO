import 'package:flutter/material.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Priced lines and their total in a card (C12, C15, C16, C48).
class BillView extends StatelessWidget {
  /// Creates the bill; [totalLabel] defaults to "Total".
  const BillView({
    required this.lines,
    required this.total,
    this.title,
    this.totalLabel,
    super.key,
  });

  /// The lines.
  final List<BillLine> lines;

  /// Amount in paisa shown at the bottom.
  final int total;

  /// Heading above the lines.
  final String? title;

  /// Label of the total.
  final String? totalLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: text.titleSmall),
            const SizedBox(height: PaoSpace.sm),
          ],
          for (final line in lines) _Line(line: line),
          const Divider(height: PaoSpace.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalLabel ?? context.t.bookingTotal,
                  style: text.titleMedium,
                ),
              ),
              Text(
                formatMoney(total, locale: context.lang),
                style: text.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final BillLine line;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: PaoSpace.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.t.bookingLine(
              context.local(line.name),
              context.count(line.quantity),
            ),
          ),
        ),
        if (line.extra) ...[
          PaoBadge(label: context.t.bookingExtra, tone: PaoTone.warning),
          const SizedBox(width: PaoSpace.sm),
        ],
        Text(formatMoney(line.total, locale: context.lang)),
      ],
    ),
  );
}
