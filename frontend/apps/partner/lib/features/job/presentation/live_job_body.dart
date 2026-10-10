import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart'
    show
        Booking,
        BookingStatus,
        ExtrasProposalStatusEnum,
        ProviderCancelInputReasonEnum,
        TimelineEntryActorEnum;
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/job/presentation/customer_card.dart';
import 'package:pao_partner/features/job/presentation/job_cubit.dart';
import 'package:pao_partner/features/job/presentation/job_items.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/features/job/presentation/reason_sheet.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

const List<BookingStatus> _steps = [
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
  BookingStatus.inProgress,
  BookingStatus.completed,
];

// Cancelling is allowed until the start code is entered (PRD §5).
const Set<BookingStatus> _cancellable = {
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
};

const Set<BookingStatus> _closed = {
  BookingStatus.cancelled,
  BookingStatus.rejected,
  BookingStatus.timedOut,
};

/// The loaded active job (M17): progress, customer, items and the next
/// action.
class LiveJobBody extends StatelessWidget {
  /// Creates the body; [state] holds a loaded job.
  const LiveJobBody({required this.state, required this.launcher, super.key});

  /// The job and the action in flight.
  final JobState state;

  /// Maps and dialler.
  final Launcher launcher;

  @override
  Widget build(BuildContext context) {
    final b = state.booking!;
    if (_closed.contains(b.status)) return _Closed(booking: b);
    final pending = b.pendingExtras;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        Text(
          context.local(b.serviceName),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(b.number),
        PaoStatusStepper(
          steps: [for (final s in _steps) context.statusText(s)],
          current: _steps.indexOf(b.status),
        ),
        CustomerCard(booking: b, launcher: launcher),
        const SizedBox(height: PaoSpace.md),
        JobItems(items: b.items, total: b.total),
        if (pending?.status == ExtrasProposalStatusEnum.pending)
          Text(
            context.t.jobExtrasWaiting(
              formatMoney(pending!.addedTotal, locale: context.lang),
            ),
          ),
        if (state.failure != null)
          Text(
            context.failureText(state.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.lg),
        ..._actions(context, b),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, Booking b) => [
    _primary(context, b),
    if (b.status == BookingStatus.inProgress) ...[
      const SizedBox(height: PaoSpace.sm),
      PaoButton(
        label: context.t.jobActionExtras,
        variant: PaoButtonVariant.outline,
        onPressed: () => _open(context, b, 'extras'),
      ),
    ],
    if (_cancellable.contains(b.status)) ...[
      const SizedBox(height: PaoSpace.sm),
      PaoButton(
        label: context.t.jobActionCancel,
        variant: PaoButtonVariant.ghost,
        onPressed: () => _cancel(context),
      ),
    ],
  ];

  Widget _primary(BuildContext context, Booking b) {
    final t = context.t;
    final cubit = context.read<JobCubit>();
    PaoButton open(String label, String part) =>
        PaoButton(label: label, onPressed: () => _open(context, b, part));
    return switch (b.status) {
      BookingStatus.accepted || BookingStatus.onTheWay => PaoButton(
        label: b.status == BookingStatus.accepted
            ? t.jobActionOnTheWay
            : t.jobActionArrived,
        loading: state.busy,
        onPressed: cubit.advance,
      ),
      BookingStatus.arrived => open(t.jobActionStart, 'start'),
      BookingStatus.inProgress => open(t.jobActionComplete, 'complete'),
      BookingStatus.completed when b.reviewedByMe != true => open(
        t.jobActionRate,
        'rate',
      ),
      BookingStatus.requested => PaoButton(
        label: t.jobActionOpenRequest,
        onPressed: () => context.go(Routes.requestOf(b.id)),
      ),
      _ => _home(context),
    };
  }

  Future<void> _open(BuildContext context, Booking b, String part) async {
    final cubit = context.read<JobCubit>();
    await context.push(Routes.job(b.id, part));
    await cubit.refresh();
  }

  Future<void> _cancel(BuildContext context) async {
    final t = context.t;
    final cubit = context.read<JobCubit>();
    final choice = await showReasonSheet(
      context,
      title: t.jobCancelTitle,
      form: ReasonSheet(
        warning: t.jobCancelWarning,
        confirm: t.jobActionCancel,
        reasons: {
          ProviderCancelInputReasonEnum.emergency: t.jobCancelEmergency,
          ProviderCancelInputReasonEnum.customerUnreachable:
              t.jobCancelUnreachable,
          ProviderCancelInputReasonEnum.unsafeLocation: t.jobCancelUnsafe,
          ProviderCancelInputReasonEnum.other: t.jobCancelOther,
        },
      ),
    );
    if (choice != null) await cubit.cancel(choice.$1, choice.$2);
  }
}

Widget _home(BuildContext context) => PaoButton(
  label: context.t.jobBackHome,
  onPressed: () => context.go(Routes.home),
);

class _Closed extends StatelessWidget {
  const _Closed({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cancel = booking.timeline
        .where((e) => e.status == BookingStatus.cancelled)
        .lastOrNull;
    return PaoMessageState(
      icon: Icons.event_busy_outlined,
      title: cancel == null ? t.jobClosedTitle : t.jobCancelledTitle,
      message: switch (cancel?.actor) {
        null => null,
        TimelineEntryActorEnum.customer => t.jobCancelledByCustomer,
        _ => t.jobCancelledOther,
      },
      action: _home(context),
    );
  }
}
