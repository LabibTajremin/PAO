import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// A provider's or customer's recent bookings; a row opens the booking in the
/// monitor when [canOpen].
class BookingSummaryList extends StatelessWidget {
  /// Creates the list.
  const BookingSummaryList({
    required this.bookings,
    required this.canOpen,
    super.key,
  });

  /// Newest first.
  final List<BookingSummary> bookings;

  /// Whether the admin may open the bookings monitor (A10).
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return Text(context.t.peopleNoBookings);
    return Column(
      children: [
        for (final b in bookings)
          PaoListRow(
            title: '${b.number} · ${context.local(b.serviceName)}',
            subtitle: [
              ?b.counterpartName,
              context.when(b.createdAt),
            ].join(' · '),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PaoMoneyText(b.total),
                PaoBadge(
                  label: bookingStatusLabel(context.t, b.status),
                  tone: bookingStatusTone(b.status),
                ),
              ],
            ),
            onTap: canOpen
                ? () => context.go(Routes.detail(Routes.bookings, b.id))
                : null,
          ),
      ],
    );
  }
}

/// Who changed an account's status, when and why; the audit entries cannot
/// be edited (PRD §6.4).
class StatusHistory extends StatelessWidget {
  /// Creates the history.
  const StatusHistory({required this.entries, super.key});

  /// Newest first.
  final List<AuditEntry> entries;

  String _title(BuildContext context, AuditEntry e) {
    final next = e.after?['status'];
    final status = AccountStatus.values
        .where((s) => s.value == next)
        .firstOrNull;
    return status == null ? e.action : accountStatusLabel(context.t, status);
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return Text(context.t.peopleHistoryEmpty);
    return Column(
      children: [
        for (final e in entries)
          PaoListRow(
            title: _title(context, e),
            subtitle: [
              ?e.reason,
              [
                context.when(e.at),
                if (e.actorRole case final role?)
                  context.t.peopleHistoryBy(role),
              ].join(' · '),
            ].join('\n'),
          ),
      ],
    );
  }
}
