import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart'
    show Booking, RejectInputReasonEnum, Timing;
import 'package:pao_core/pao_core.dart' show ApiFailure;
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/billing/presentation/billing_labels.dart';
import 'package:pao_partner/features/job/presentation/job_items.dart';
import 'package:pao_partner/features/job/presentation/reason_sheet.dart';
import 'package:pao_partner/features/requests/presentation/request_cubit.dart';
import 'package:pao_partner/shared/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A loaded request: countdown, service, timing, area, items and answers.
class RequestBody extends StatelessWidget {
  /// Creates the body for [booking].
  const RequestBody({required this.booking, required this.state, super.key});

  /// The request.
  final Booking booking;

  /// Countdown and the answer in flight.
  final RequestState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final left = state.left;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        if (left != null)
          PaoCard(
            highlighted: true,
            child: Text(
              context.t.reqTimeLeft(context.clock(left)),
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: PaoSpace.lg),
        Text(context.local(booking.serviceName), style: text.headlineSmall),
        PaoListRow(
          leading: const Icon(Icons.schedule_outlined),
          title: _when(context),
        ),
        PaoListRow(
          leading: const Icon(Icons.place_outlined),
          title: booking.address.area,
          subtitle: _distance(context),
        ),
        if (booking.note case final note?)
          PaoListRow(
            leading: const Icon(Icons.notes_outlined),
            title: context.t.reqNote,
            subtitle: note,
          ),
        JobItems(items: booking.items, total: booking.total),
        const SizedBox(height: PaoSpace.lg),
        ..._answers(context),
      ],
    );
  }

  String _when(BuildContext context) => switch (booking.scheduledAt) {
    final at? when booking.timing == Timing.scheduled => context.t.reqScheduled(
      formatDhaka(at, pattern: 'd MMM, h:mm a', locale: context.lang),
    ),
    _ => context.t.reqAsap,
  };

  String? _distance(BuildContext context) =>
      switch (booking.address.distanceM) {
        final m? => context.t.reqDistance(
          NumberFormat('0.0', context.lang).format(m / 1000),
        ),
        null => null,
      };

  // A due refusal names both amounts when the API sends them (ADR-0036).
  String _failureText(BuildContext context) => switch (state.failure) {
    ApiFailure(
      code: 'MERCHANT_DUE_LIMIT',
      details: {'duePaisa': final int due, 'blockAmountPaisa': final int limit},
    ) =>
      context.t.billBannerBlocked(context.money(due), context.money(limit)),
    final failure => context.failureText(failure)!,
  };

  List<Widget> _answers(BuildContext context) {
    final cubit = context.read<RequestCubit>();
    return [
      if (state.failure != null)
        Text(
          _failureText(context),
          style: const TextStyle(color: PaoColors.danger),
        ),
      // Blocked by the due: the request stays open, so paying is the way on.
      if (state.failure?.code == 'MERCHANT_DUE_LIMIT') ...[
        const SizedBox(height: PaoSpace.sm),
        PaoButton(
          label: context.t.billPayNow,
          variant: PaoButtonVariant.soft,
          onPressed: () => context.push(Routes.pay),
        ),
      ],
      const SizedBox(height: PaoSpace.sm),
      PaoButton(
        label: context.t.reqAccept,
        loading: state.busy,
        onPressed: cubit.accept,
      ),
      const SizedBox(height: PaoSpace.sm),
      PaoButton(
        label: context.t.reqReject,
        variant: PaoButtonVariant.outline,
        onPressed: state.busy ? null : () => _reject(context),
      ),
    ];
  }

  Future<void> _reject(BuildContext context) async {
    final t = context.t;
    final cubit = context.read<RequestCubit>();
    final choice = await showReasonSheet(
      context,
      title: t.reqRejectTitle,
      form: ReasonSheet(
        confirm: t.reqReject,
        reasons: {
          RejectInputReasonEnum.busy: t.reqReasonBusy,
          RejectInputReasonEnum.tooFar: t.reqReasonTooFar,
          RejectInputReasonEnum.notMyService: t.reqReasonNotMyService,
          RejectInputReasonEnum.other: t.reqReasonOther,
        },
      ),
    );
    if (choice != null) await cubit.reject(choice.$1, choice.$2);
  }
}
