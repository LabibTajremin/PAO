import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';
import 'package:pao_customer/features/booking/presentation/bill.dart';
import 'package:pao_customer/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_customer/features/delivery/presentation/order_cubit.dart';
import 'package:pao_customer/features/location/presentation/address_labels.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The order form's sections, top to bottom.
class OrderForm extends StatefulWidget {
  /// Creates the form.
  const OrderForm({
    required this.state,
    required this.options,
    required this.draft,
    super.key,
  });

  /// The form's choices.
  final OrderState state;

  /// The service, provider and addresses.
  final BookingOptions options;

  /// The chosen items.
  final BookingDraft draft;

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickStart(OrderCubit cubit, DateTime first) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.start ?? first,
      firstDate: first,
      lastDate: first.add(const Duration(days: 90)),
    );
    if (picked != null) cubit.start(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = widget.state;
    final cubit = context.read<OrderCubit>();
    final schedule = s.schedule!;
    final lines = draftLines(widget.options.service, widget.draft.items);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        _Section(t.orderRepeat, [
          for (final p in schedule.patterns)
            PaoChip(
              label: patternLabel(t, p),
              selected: s.pattern == p,
              onTap: () => cubit.pattern(p),
            ),
        ]),
        if (s.pattern case DeliveryPattern.weekdays || DeliveryPattern.weekly)
          _Section(t.orderDays, [
            for (var d = 0; d < 7; d++)
              PaoChip(
                label: weekdayLabel(locale, d),
                selected: s.weekdays.contains(d),
                onTap: () => cubit.day(d),
              ),
          ]),
        if (s.pattern == DeliveryPattern.monthly)
          _Section(t.orderDayOfMonth, [
            PaoStepper(
              value: s.dayOfMonth,
              min: 1,
              max: 31,
              onChanged: cubit.dayOfMonth,
            ),
          ]),
        _Section(t.orderWindow, [
          for (final (i, w) in schedule.windows.indexed)
            PaoChip(
              label: '${w.start}–${w.end}',
              selected: s.window == i,
              onTap: () => cubit.window(i),
            ),
        ]),
        PaoListRow(
          title: t.orderStart,
          subtitle: DateFormat.yMMMEd(locale).format(s.start!),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () => _pickStart(cubit, s.start!),
        ),
        if (s.repeats)
          _Section(t.orderCount, [
            PaoStepper(value: s.count, min: 1, max: 60, onChanged: cubit.count),
          ]),
        _Section(t.bookingsAddress, [
          for (final a in widget.options.addresses)
            PaoChip(
              label: '${addressLabelName(t, a.label)} · ${a.area}',
              selected: s.addressId == a.id,
              onTap: () => cubit.address(a.id),
            ),
        ]),
        BillView(
          title: t.orderPerDelivery,
          lines: lines,
          total: lines.fold(0, (sum, l) => sum + l.total),
        ),
        const SizedBox(height: PaoSpace.lg),
        PaoTextField(label: t.orderNote, controller: _note, maxLines: 2),
        const SizedBox(height: PaoSpace.lg),
        Text(t.orderCash, textAlign: TextAlign.center),
        if (context.failureText(s.failure) case final why?)
          Text(why, style: TextStyle(color: context.pao.dangerInk)),
        const SizedBox(height: PaoSpace.md),
        PaoButton(
          label: t.orderConfirm,
          loading: s.busy,
          onPressed: s.addressId == null
              ? null
              : () => cubit.confirm(_note.text),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PaoSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: PaoSpace.sm),
        Wrap(spacing: PaoSpace.sm, runSpacing: PaoSpace.sm, children: children),
      ],
    ),
  );
}
