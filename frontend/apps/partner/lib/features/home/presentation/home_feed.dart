import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show BookingSummary;
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/home/domain/home_repository.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Today's earnings, the active job card and open requests.
class HomeFeed extends StatelessWidget {
  /// Creates the feed.
  const HomeFeed({required this.summary, super.key});

  /// The loaded dashboard.
  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final title = Theme.of(context).textTheme.titleMedium;
    final active = summary.active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _earnings(context),
        if (active != null) ...[
          const SizedBox(height: PaoSpace.lg),
          Text(t.homeActiveJob, style: title),
          _job(context, active, Routes.job(active.id, 'live')),
        ],
        const SizedBox(height: PaoSpace.lg),
        Text(t.homeRequests, style: title),
        if (summary.requests.isEmpty)
          PaoEmptyState(title: t.homeNoRequests, message: t.homeNoRequestsBody)
        else
          for (final r in summary.requests)
            _job(context, r, Routes.requestOf(r.id)),
      ],
    );
  }

  Widget _earnings(BuildContext context) => PaoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t.homeToday),
        PaoMoneyText(
          summary.earnedToday,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(context.t.homeJobsToday(summary.jobsToday)),
      ],
    ),
  );

  Widget _job(BuildContext context, BookingSummary job, String route) =>
      Padding(
        padding: const EdgeInsets.only(top: PaoSpace.sm),
        child: PaoCard(
          highlighted: identical(job, summary.active),
          onTap: () => _open(context, route),
          child: PaoListRow(
            title: context.local(job.serviceName),
            subtitle: [
              context.statusText(job.status),
              ?job.counterpartName,
            ].join(' · '),
            trailing: PaoMoneyText(job.total),
          ),
        ),
      );

  // Pushed rather than replaced so the home screen, and with it the
  // heartbeat, stays alive underneath.
  Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<LoadCubit<HomeSummary>>();
    await context.push(route);
    await cubit.refresh();
  }
}
