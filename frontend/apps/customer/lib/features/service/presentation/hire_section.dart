import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/service/domain/selection.dart';
import 'package:pao_customer/features/service/presentation/selection_cubit.dart';
import 'package:pao_customer/features/service/presentation/sub_service_tile.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_customer/shared/price_units.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Duty and start of a duration hire such as a driver (C44).
class HireSection extends StatelessWidget {
  /// Creates the section; [now] bounds the start.
  const HireSection({
    required this.service,
    required this.selection,
    required this.now,
    super.key,
  });

  /// The service.
  final Service service;

  /// The current selection.
  final Selection selection;

  /// The current time.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SelectionCubit>();
    final heading = Theme.of(context).textTheme.titleSmall;
    final subs = bookable(service);
    final chosen = [
      for (final s in subs)
        if (selection.items.containsKey(s.id)) s,
    ].firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PaoSpace.sm,
      children: [
        Text(context.t.svcHireDuty, style: heading),
        Wrap(
          spacing: PaoSpace.sm,
          runSpacing: PaoSpace.sm,
          children: [
            for (final s in subs)
              PaoChip(
                label:
                    '${context.local(s.name)} · ${priceWithUnit(context, s)}',
                selected: s == chosen,
                onTap: () => cubit.only(s.id, 1),
              ),
          ],
        ),
        if (chosen != null) ...[
          _Duty(sub: chosen, quantity: selection.items[chosen.id]!),
          IncludedList(sub: chosen),
        ],
        const SizedBox(height: PaoSpace.sm),
        Text(context.t.svcHireStart, style: heading),
        Row(
          spacing: PaoSpace.sm,
          children: [
            Expanded(child: _dayButton(context)),
            Expanded(child: _timeButton(context)),
          ],
        ),
      ],
    );
  }

  Widget _dayButton(BuildContext context) {
    final day = selection.day;
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(
        day == null
            ? context.t.svcHireDate
            : DateFormat('EEE, d MMM', context.lang).format(day),
      ),
      onPressed: () => _pickDay(context),
    );
  }

  Widget _timeButton(BuildContext context) {
    final m = selection.minutes;
    return OutlinedButton.icon(
      icon: const Icon(Icons.schedule),
      label: Text(
        m == null
            ? context.t.svcHireTime
            : TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context),
      ),
      onPressed: () => _pickTime(context),
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final cubit = context.read<SelectionCubit>();
    final local = now.toUtc().add(dhakaOffset);
    final today = DateTime(local.year, local.month, local.day);
    final day = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      initialDate: selection.day ?? today,
    );
    if (day != null) cubit.day(day);
  }

  Future<void> _pickTime(BuildContext context) async {
    final cubit = context.read<SelectionCubit>();
    final m = selection.minutes ?? 9 * 60;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (time != null) cubit.time(time.hour * 60 + time.minute);
  }
}

class _Duty extends StatelessWidget {
  const _Duty({required this.sub, required this.quantity});

  final SubService sub;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final n = context.count(quantity);
    final label = switch (sub.unit) {
      PriceUnit.hour => context.t.svcHours(quantity, n),
      PriceUnit.day => context.t.svcDays(quantity, n),
      _ => n,
    };
    return Row(
      children: [
        Expanded(child: Text(label)),
        PaoStepper(
          value: quantity,
          min: 1,
          max: sub.maxQuantity ?? defaultMaxQuantity,
          onChanged: (q) => context.read<SelectionCubit>().only(sub.id, q),
        ),
      ],
    );
  }
}
