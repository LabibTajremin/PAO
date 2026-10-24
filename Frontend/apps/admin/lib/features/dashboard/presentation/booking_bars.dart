import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Height of the tallest bar.
const _chartHeight = 160.0;

/// Bookings per day as bars: the full bar is every booking that day, the
/// darker part the ones completed. Hovering a bar names the day and counts.
class BookingBars extends StatelessWidget {
  /// Creates the chart.
  const BookingBars({required this.days, super.key});

  /// One entry per day, oldest first.
  final List<DashboardBookingsPerDayInner> days;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: PaoSpace.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(t.dashBookingsPerDay, style: _title(context)),
            _Key(color: context.pao.accent.soft, label: t.dashLegendTotal),
            _Key(
              color: context.pao.accent.primary,
              label: t.dashLegendCompleted,
            ),
          ],
        ),
        const SizedBox(height: PaoSpace.lg),
        if (days.isEmpty) Text(t.dashNoBookings) else ..._chart(context),
      ],
    );
  }

  TextStyle? _title(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;

  List<Widget> _chart(BuildContext context) {
    final peak = days.map((d) => d.total).fold(1, math.max);
    final caption = Theme.of(context).textTheme.bodySmall;
    return [
      SizedBox(
        height: _chartHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (final d in days) _Bar(day: d, peak: peak)],
        ),
      ),
      const SizedBox(height: PaoSpace.sm),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.day(days.first.date), style: caption),
          Text(context.day(days.last.date), style: caption),
        ],
      ),
    ];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.peak});

  final DashboardBookingsPerDayInner day;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final done = day.total == 0 ? 0.0 : day.completed / day.total;
    return Expanded(
      child: Tooltip(
        message: context.t.dashDayTip(
          context.day(day.date),
          context.count(day.total),
          context.count(day.completed),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            height: _chartHeight * day.total / peak,
            color: accent.soft,
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: done,
              widthFactor: 1,
              child: ColoredBox(color: accent.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(dimension: 10, child: ColoredBox(color: color)),
      const SizedBox(width: PaoSpace.xs),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
