import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart'
    show Booking, CustomerCancelInputReasonEnum;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/cancel/data/api_cancel_repository.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_cubit.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_views.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Cancel a booking with a reason (C52), the result (C53), or why it cannot
/// be cancelled once the job has started (C54).
class CancelPage extends StatefulWidget {
  /// Creates the page.
  const CancelPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  State<CancelPage> createState() => _CancelPageState();
}

class _CancelPageState extends State<CancelPage> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        CancelCubit(ApiCancelRepository(widget.services.api), widget.bookingId)
          ..load().ignore(),
    child: BlocBuilder<CancelCubit, CancelState>(
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.cancelTitle),
        body: ViewStateView<Booking>(
          state: s.view,
          onRetry: context.read<CancelCubit>().load,
          builder: (_, b) => switch (s.outcome) {
            null => _form(context, s),
            final outcome => CancelResult(outcome: outcome, booking: b),
          },
        ),
      ),
    ),
  );

  Widget _form(BuildContext context, CancelState s) {
    final t = context.t;
    final cubit = context.read<CancelCubit>();
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        Text(t.cancelQuestion, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: PaoSpace.xs),
        Text(t.cancelFree, style: const TextStyle(color: PaoColors.success)),
        const SizedBox(height: PaoSpace.md),
        ..._reasons(context, s),
        const SizedBox(height: PaoSpace.md),
        PaoTextField(
          label: t.cancelNote,
          controller: _note,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
        ),
        if (s.failure != null)
          Text(
            context.failureText(s.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.cancelConfirm,
          variant: PaoButtonVariant.danger,
          loading: s.busy,
          onPressed: s.reason == null ? null : () => cubit.submit(_note.text),
        ),
        PaoButton(
          label: t.cancelKeep,
          variant: PaoButtonVariant.ghost,
          onPressed: () => leaveCancel(context, widget.bookingId),
        ),
      ],
    );
  }
}

List<Widget> _reasons(BuildContext context, CancelState s) => [
  for (final reason in CustomerCancelInputReasonEnum.values)
    PaoListRow(
      leading: Icon(
        s.reason == reason
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
      ),
      title: _reasonText(context.t, reason),
      onTap: () => context.read<CancelCubit>().choose(reason),
    ),
];

String _reasonText(CustomerL10n t, CustomerCancelInputReasonEnum r) =>
    switch (r) {
      CustomerCancelInputReasonEnum.changedMind => t.cancelReasonChangedMind,
      CustomerCancelInputReasonEnum.foundOtherProvider =>
        t.cancelReasonOtherProvider,
      CustomerCancelInputReasonEnum.providerLate => t.cancelReasonLate,
      CustomerCancelInputReasonEnum.bookedByMistake => t.cancelReasonMistake,
      _ => t.cancelReasonOther,
    };

/// Back to where the cancel screen was opened from, or the booking's detail
/// when it was opened directly.
void leaveCancel(BuildContext context, String bookingId) =>
    context.canPop() ? context.pop() : context.go(Routes.booking(bookingId));
