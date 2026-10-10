import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart' show ExtrasProposalStatusEnum;
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/data/api_job_repository.dart';
import 'package:pao_partner/features/job/presentation/extras_cubit.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Extra catalog items for the customer to approve (M19, C-09).
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
        ExtrasCubit(ApiJobRepository(services.api), bookingId)..load().ignore(),
    child: BlocBuilder<ExtrasCubit, ExtrasState>(
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.jobExtrasTitle),
        body: ViewStateView<ExtrasData>(
          state: s.view,
          onRetry: context.read<ExtrasCubit>().load,
          isEmpty: (d) => d.options.isEmpty && !d.waiting,
          empty: PaoEmptyState(
            title: context.t.jobExtrasEmpty,
            action: _back(context),
          ),
          builder: (context, d) =>
              d.waiting ? _waiting(context, d) : _picker(context, d, s),
        ),
      ),
    ),
  );

  Widget _back(BuildContext context) => PaoButton(
    label: context.t.jobBackToJob,
    variant: PaoButtonVariant.outline,
    expand: false,
    onPressed: () => context.leave(Routes.job(bookingId, 'live')),
  );

  Widget _waiting(BuildContext context, ExtrasData d) => PaoMessageState(
    icon: Icons.hourglass_top_outlined,
    title: context.t.jobExtrasWaitingTitle,
    message: context.t.jobExtrasWaiting(
      formatMoney(d.booking.pendingExtras!.addedTotal, locale: context.lang),
    ),
    action: _back(context),
  );

  Widget _picker(BuildContext context, ExtrasData d, ExtrasState s) {
    final cubit = context.read<ExtrasCubit>();
    final decided = d.booking.pendingExtras?.status;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        if (decided != null)
          PaoBanner(
            icon: Icons.info_outline,
            message: decided == ExtrasProposalStatusEnum.approved
                ? context.t.jobExtrasApproved
                : context.t.jobExtrasDeclined,
          ),
        for (final option in d.options)
          PaoListRow(
            title: context.local(option.name),
            subtitle: formatMoney(option.price, locale: context.lang),
            trailing: PaoStepper(
              value: s.quantities[option.id] ?? 0,
              max: option.maxQuantity ?? 10,
              onChanged: (q) => cubit.pick(option.id, q),
            ),
          ),
        if (s.failure != null)
          Text(
            context.failureText(s.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.lg),
        PaoButton(
          label: context.t.jobExtrasSend(
            formatMoney(s.addedTotal, locale: context.lang),
          ),
          loading: s.busy,
          onPressed: s.quantities.isEmpty ? null : cubit.submit,
        ),
      ],
    );
  }
}
