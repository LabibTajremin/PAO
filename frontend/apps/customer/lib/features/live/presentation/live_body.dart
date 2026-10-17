import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart'
    show Booking, BookingStatus, ExtrasProposalStatusEnum;
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/presentation/bill.dart';
import 'package:pao_customer/features/booking/presentation/provider_card.dart';
import 'package:pao_customer/features/booking/presentation/track_cubit.dart';
import 'package:pao_customer/features/booking/presentation/waiting_views.dart';
import 'package:pao_customer/features/connectivity/presentation/stale_notice.dart';
import 'package:pao_customer/features/live/presentation/live_sections.dart';
import 'package:pao_customer/features/live/presentation/start_code_card.dart';
import 'package:pao_customer/features/live/presentation/start_code_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The loaded active booking: status, code, extras, provider, bill, actions.
class LiveBody extends StatelessWidget {
  /// Creates the body; [state] holds a loaded booking.
  const LiveBody({required this.state, required this.services, super.key});

  /// The tracked booking.
  final TrackState state;

  /// App services, for the dialler.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final b = state.booking!;
    if (b.status == BookingStatus.cancelled) return const CancelledView();
    final provider = b.provider;
    final phone = provider?.phone;
    final pending = b.pendingExtras?.status == ExtrasProposalStatusEnum.pending;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        if (state.stale) const StaleNotice(),
        LiveHeadline(booking: b),
        const SizedBox(height: PaoSpace.md),
        LiveStepper(status: b.status),
        if (codeStatuses.contains(b.status)) ...[
          const SizedBox(height: PaoSpace.md),
          const StartCodeCard(),
        ],
        if (pending) ...[
          const SizedBox(height: PaoSpace.md),
          ExtrasNotice(booking: b, onReview: () => _open(context, b, 'extras')),
        ],
        const SizedBox(height: PaoSpace.md),
        if (provider != null)
          PartyCard.party(
            provider,
            onCall: phone == null ? null : () => services.launcher.call(phone),
          ),
        const SizedBox(height: PaoSpace.md),
        AddressRow(booking: b),
        const SizedBox(height: PaoSpace.md),
        BillView(
          title: context.local(b.serviceName),
          lines: [for (final item in b.items) BillLine.of(item)],
          total: b.total,
        ),
        const SizedBox(height: PaoSpace.xl),
        _action(context, b),
      ],
    );
  }

  // Cancelling is free until the start code is entered (D8); after that,
  // problems go through a report instead (C54).
  Widget _action(BuildContext context, Booking b) =>
      codeStatuses.contains(b.status)
      ? PaoButton(
          label: context.t.liveCancel,
          variant: PaoButtonVariant.outline,
          onPressed: () => _open(context, b, 'cancel'),
        )
      : PaoButton(
          label: context.t.liveReport,
          variant: PaoButtonVariant.ghost,
          onPressed: () => _open(context, b, 'report'),
        );

  Future<void> _open(BuildContext context, Booking b, String part) async {
    final cubit = context.read<TrackCubit>();
    await context.push(Routes.booking(b.id, part));
    await cubit.refresh();
  }
}
