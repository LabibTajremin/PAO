import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The priced lines of a booking or receipt, extras marked, and the total.
class BillRows extends StatelessWidget {
  /// Creates the rows.
  const BillRows({required this.items, required this.total, super.key});

  /// Lines copied from the catalog, including approved extras.
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
          subtitle: item.extra ? context.t.bookingsExtra : null,
          trailing: PaoMoneyText(item.total),
        ),
      const Divider(),
      PaoListRow(
        title: context.t.bookingsTotal,
        trailing: PaoMoneyText(
          total,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}
