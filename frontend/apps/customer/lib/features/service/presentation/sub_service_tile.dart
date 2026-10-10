import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_customer/shared/price_units.dart';
import 'package:pao_ui/pao_ui.dart';

/// The most of one sub-service a booking may hold when the catalog sets no
/// limit; the API caps an item at 50.
const defaultMaxQuantity = 10;

/// One sub-service with its price, quantity and what is included (C09).
class SubServiceTile extends StatelessWidget {
  /// Creates the tile.
  const SubServiceTile({
    required this.sub,
    required this.quantity,
    required this.onChanged,
    super.key,
  });

  /// The sub-service.
  final SubService sub;

  /// Chosen quantity.
  final int quantity;

  /// Called with the new quantity.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final description = sub.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        highlighted: quantity > 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.local(sub.name), style: text.titleSmall),
                      Text(priceWithUnit(context, sub), style: text.bodyMedium),
                    ],
                  ),
                ),
                PaoStepper(
                  value: quantity,
                  max: sub.maxQuantity ?? defaultMaxQuantity,
                  onChanged: onChanged,
                ),
              ],
            ),
            if (description != null)
              Text(context.local(description), style: text.bodySmall),
            IncludedList(sub: sub),
          ],
        ),
      ),
    );
  }
}

/// What a sub-service includes and excludes.
class IncludedList extends StatelessWidget {
  /// Creates the list.
  const IncludedList({required this.sub, super.key});

  /// The sub-service.
  final SubService sub;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void add(String heading, List<LocalizedText>? items, IconData icon) {
      if (items == null || items.isEmpty) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: PaoSpace.sm),
          child: Text(heading, style: Theme.of(context).textTheme.labelLarge),
        ),
      );
      for (final item in items) {
        rows.add(
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: PaoSpace.xs),
              Expanded(child: Text(context.local(item))),
            ],
          ),
        );
      }
    }

    add(context.t.svcIncluded, sub.inclusions, Icons.check);
    add(context.t.svcExcluded, sub.exclusions, Icons.close);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
