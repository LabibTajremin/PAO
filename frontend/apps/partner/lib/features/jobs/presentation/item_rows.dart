import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The priced lines of a job or receipt and their total.
class ItemRows extends StatelessWidget {
  /// Creates the rows.
  const ItemRows({required this.items, required this.total, super.key});

  /// Lines copied from the catalog.
  final List<BookingItem> items;

  /// Total in paisa.
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final item in items)
        PaoListRow(
          title:
              '${context.local(item.name)} × ${context.count(item.quantity)}',
          subtitle: item.extra ? context.t.jobsExtra : null,
          trailing: PaoMoneyText(item.total),
        ),
      PaoListRow(
        title: context.t.jobsTotal,
        trailing: PaoMoneyText(
          total,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}
