import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart' show ServiceModel;
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/presentation/bill.dart';
import 'package:pao_customer/features/booking/presentation/provider_card.dart';
import 'package:pao_customer/features/booking/presentation/setup_cubit.dart';
import 'package:pao_customer/features/booking/presentation/setup_sections.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The loaded set-up form: provider, order, timing, address, note, payment.
class SetupBody extends StatefulWidget {
  /// Creates the form; [now] is the app clock for the date picker.
  const SetupBody({required this.state, required this.now, super.key});

  /// The form state with loaded options.
  final SetupState state;

  /// The app clock.
  final DateTime Function() now;

  @override
  State<SetupBody> createState() => _SetupBodyState();
}

class _SetupBodyState extends State<SetupBody> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final options = s.options!;
    final cubit = context.read<SetupCubit>();
    final lines = cubit.lines;
    final p = options.provider;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        PartyCard(
          name: p.name,
          photoUrl: p.photoUrl,
          badge: p.badge,
          rating: p.rating.average,
          ratingCount: p.rating.count,
        ),
        const SizedBox(height: PaoSpace.md),
        BillView(
          title: context.local(options.service.name),
          lines: lines,
          total: billTotal(lines),
        ),
        const SizedBox(height: PaoSpace.lg),
        WhenSection(
          state: s,
          now: widget.now,
          fixed: options.service.serviceModel == ServiceModel.durationHire,
        ),
        const SizedBox(height: PaoSpace.lg),
        WhereSection(state: s),
        const SizedBox(height: PaoSpace.lg),
        _noteField(context),
        const SizedBox(height: PaoSpace.lg),
        const PaymentSection(),
        ..._confirm(context, s, billTotal(lines)),
      ],
    );
  }

  Widget _noteField(BuildContext context) => PaoTextField(
    label: context.t.bookingNoteLabel,
    hint: context.t.bookingNoteHint,
    controller: _note,
    maxLines: 3,
    inputFormatters: [LengthLimitingTextInputFormatter(500)],
  );

  List<Widget> _confirm(BuildContext context, SetupState s, int total) => [
    if (s.failure != null) ...[
      const SizedBox(height: PaoSpace.md),
      Text(
        context.failureText(s.failure)!,
        style: const TextStyle(color: PaoColors.danger),
      ),
    ],
    const SizedBox(height: PaoSpace.xl),
    PaoButton(
      label: context.t.bookingConfirm(formatMoney(total, locale: context.lang)),
      loading: s.busy,
      onPressed: s.addressId == null
          ? null
          : () => context.read<SetupCubit>().confirm(_note.text),
    ),
  ];
}
