import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/earnings/data/api_earnings_repository.dart';
import 'package:pao_partner/features/earnings/presentation/earnings_summary_card.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Earnings by day, week or month, and by job (M26, M27).
class EarningsPage extends StatefulWidget {
  /// Creates the page.
  const EarningsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late final ApiEarningsRepository _repo = ApiEarningsRepository(
    widget.services.api,
  );
  EarningsPeriod _period = EarningsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final period = _period;
    final t = context.t;
    return BlocProvider(
      create: (_) => PagedCubit<EarningsJob>(
        (cursor) => _repo.jobs(period, cursor: cursor),
      ).loading(),
      child: BlocProvider(
        key: ValueKey(period),
        create: (_) =>
            LoadCubit<EarningsSummary>(() => _repo.summary(period)).loading(),
        child: Scaffold(
          appBar: PaoAppBar(title: t.earnTitle),
          body: PagedView<EarningsJob>(
            header: [
              PaoSegmented<EarningsPeriod>(
                segments: {
                  EarningsPeriod.day: t.earnDay,
                  EarningsPeriod.week: t.earnWeek,
                  EarningsPeriod.month: t.earnMonth,
                },
                selected: period,
                onChanged: (value) => setState(() => _period = value),
              ),
              const SizedBox(height: PaoSpace.lg),
              const EarningsSummaryCard(),
              const SizedBox(height: PaoSpace.lg),
              Text(t.earnByJob, style: Theme.of(context).textTheme.titleMedium),
            ],
            itemBuilder: (_, job) => _JobEarning(job: job),
            empty: PaoEmptyState(
              title: t.earnEmptyTitle,
              message: t.earnEmptyBody,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobEarning extends StatelessWidget {
  const _JobEarning({required this.job});

  final EarningsJob job;

  @override
  Widget build(BuildContext context) => PaoListRow(
    title: context.local(job.serviceName),
    subtitle: '${job.number} · ${context.when(job.completedAt)}',
    trailing: PaoMoneyText(job.total),
    onTap: () => context.push(Routes.job(job.bookingId)),
  );
}
