import 'package:flutter/material.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Who moved a booking to a status.
String actorLabel(AdminL10n t, TimelineEntryActorEnum actor) => switch (actor) {
  TimelineEntryActorEnum.customer => t.bookingsCustomer,
  TimelineEntryActorEnum.provider => t.bookingsProvider,
  TimelineEntryActorEnum.system => t.bookingsActorSystem,
  TimelineEntryActorEnum.admin => t.bookingsActorAdmin,
};

/// The latest time the booking entered [status], if it did.
TimelineEntry? reached(List<TimelineEntry> timeline, BookingStatus status) =>
    timeline.where((e) => e.status == status).lastOrNull;

/// Every status change of a booking, oldest first, with who made it and why.
class BookingTimeline extends StatelessWidget {
  /// Creates the timeline.
  const BookingTimeline({required this.entries, super.key});

  /// Status changes, oldest first.
  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return Section(
      title: t.bookingsTimeline,
      child: Column(
        children: [
          for (final (i, e) in entries.indexed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PaoSpace.md,
              children: [
                _Dot(last: i == entries.length - 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: PaoSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookingStatusLabel(t, e.status),
                          style: text.titleSmall,
                        ),
                        Text(
                          '${context.when(e.at)} · ${actorLabel(t, e.actor)}',
                          style: text.bodySmall,
                        ),
                        if (e.reason case final reason?) Text(reason),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.last});

  final bool last;

  @override
  Widget build(BuildContext context) => Icon(
    last ? Icons.radio_button_checked : Icons.circle,
    size: 14,
    color: last ? context.pao.accent.primary : PaoColors.textTertiary,
  );
}
