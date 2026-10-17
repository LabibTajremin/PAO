import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking, ExtrasProposal;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/presentation/bill.dart';
import 'package:pao_customer/features/live/data/api_live_repository.dart';
import 'package:pao_customer/features/live/presentation/extras_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Extra items the provider added, with fixed prices, for approval (C15).
class ExtrasPage extends StatelessWidget {
  /// Creates the page.
  const ExtrasPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ExtrasCubit(ApiLiveRepository(services.api), bookingId)
          ..load().ignore(),
    child: BlocConsumer<ExtrasCubit, ExtrasState>(
      listenWhen: (_, s) => s.done,
      listener: (context, _) => _back(context),
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.liveApprovalTitle),
        body: ViewStateView<Booking>(
          state: s.view,
          onRetry: context.read<ExtrasCubit>().load,
          isEmpty: (_) => s.pending == null,
          empty: PaoEmptyState(
            title: context.t.liveApprovalNone,
            action: PaoButton(
              label: context.common.actionBack,
              expand: false,
              onPressed: () => _back(context),
            ),
          ),
          builder: (_, _) => _Proposal(state: s, proposal: s.pending!),
        ),
      ),
    ),
  );

  void _back(BuildContext context) => context.canPop()
      ? context.pop()
      : context.go(Routes.booking(bookingId, 'live'));
}

class _Proposal extends StatelessWidget {
  const _Proposal({required this.state, required this.proposal});

  final ExtrasState state;
  final ExtrasProposal proposal;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        Text(t.liveApprovalHeading, style: text.titleLarge),
        const SizedBox(height: PaoSpace.xs),
        Text(
          t.liveApprovalBody,
          style: const TextStyle(color: PaoColors.textSecondary),
        ),
        const SizedBox(height: PaoSpace.lg),
        BillView(
          lines: [for (final item in proposal.items) BillLine.of(item)],
          total: proposal.addedTotal,
          totalLabel: t.liveApprovalAdded,
        ),
        const SizedBox(height: PaoSpace.md),
        PaoListRow(
          title: t.liveApprovalNewTotal,
          trailing: Text(
            formatMoney(proposal.newTotal, locale: context.lang),
            style: text.titleMedium,
          ),
        ),
        if (state.failure != null)
          Text(
            context.failureText(state.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.xl),
        ..._decision(context),
      ],
    );
  }

  List<Widget> _decision(BuildContext context) {
    final cubit = context.read<ExtrasCubit>();
    return [
      PaoButton(
        label: context.t.liveApprovalApprove,
        loading: state.busy,
        onPressed: () => cubit.decide(approve: true),
      ),
      const SizedBox(height: PaoSpace.sm),
      PaoButton(
        label: context.t.liveApprovalDecline,
        variant: PaoButtonVariant.outline,
        onPressed: state.busy ? null : () => cubit.decide(approve: false),
      ),
    ];
  }
}
