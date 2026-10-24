import 'package:flutter/material.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The priced lines of a booking, extras marked, and the total.
class BookingItems extends StatelessWidget {
  /// Creates the section.
  const BookingItems({required this.booking, super.key});

  /// The booking.
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Section(
      title: t.bookingsItems,
      child: Column(
        children: [
          for (final item in booking.items) ItemRow(item: item),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.bookingsTotal,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              PaoMoneyText(booking.total),
            ],
          ),
        ],
      ),
    );
  }
}

/// One priced line: name, quantity × unit price, line total.
class ItemRow extends StatelessWidget {
  /// Creates the row.
  const ItemRow({required this.item, super.key});

  /// The line.
  final BookingItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PaoListRow(
      title: context.local(item.name),
      subtitle: t.bookingsQty(
        context.count(item.quantity),
        context.money(item.unitPrice),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PaoMoneyText(item.total),
          if (item.extra)
            PaoBadge(label: t.bookingsExtra, tone: PaoTone.accent),
        ],
      ),
    );
  }
}

/// Extra work the provider proposed during the job and its answer.
class ExtrasSection extends StatelessWidget {
  /// Creates the section.
  const ExtrasSection({required this.extras, super.key});

  /// The proposal.
  final ExtrasProposal extras;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (label, tone) = switch (extras.status) {
      ExtrasProposalStatusEnum.pending => (
        t.bookingsExtrasPending,
        PaoTone.warning,
      ),
      ExtrasProposalStatusEnum.approved => (
        t.bookingsExtrasApproved,
        PaoTone.success,
      ),
      ExtrasProposalStatusEnum.declined => (
        t.bookingsExtrasDeclined,
        PaoTone.neutral,
      ),
    };
    return Section(
      title: t.bookingsExtras,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaoBadge(label: label, tone: tone),
          for (final item in extras.items) ItemRow(item: item),
          Text(
            t.bookingsExtrasAdded(
              context.money(extras.addedTotal),
              context.money(extras.newTotal),
            ),
          ),
          Text(
            context.when(extras.proposedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
