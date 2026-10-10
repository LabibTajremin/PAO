import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart' show BookingItem;
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The booked lines with quantities and the total.
class JobItems extends StatelessWidget {
  /// Creates the list.
  const JobItems({required this.items, required this.total, super.key});

  /// Booked lines, extras included.
  final List<BookingItem> items;

  /// Total in paisa.
  final int total;

  @override
  Widget build(BuildContext context) {
    final strong = Theme.of(context).textTheme.titleMedium;
    return PaoCard(
      child: Column(
        children: [
          for (final item in items)
            PaoListRow(
              title: context.local(item.name),
              subtitle: item.extra
                  ? context.t.jobExtraQuantity(item.quantity)
                  : context.t.jobQuantity(item.quantity),
              trailing: PaoMoneyText(item.total),
            ),
          const Divider(),
          Row(
            children: [
              Expanded(child: Text(context.t.jobTotal, style: strong)),
              PaoMoneyText(total, style: strong),
            ],
          ),
        ],
      ),
    );
  }
}
