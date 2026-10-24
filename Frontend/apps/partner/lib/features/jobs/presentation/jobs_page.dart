import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/jobs/data/api_jobs_repository.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';
import 'package:pao_partner/features/jobs/presentation/status_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Upcoming and past jobs (M23).
class JobsPage extends StatefulWidget {
  /// Creates the page.
  const JobsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  late final ApiJobsRepository _repo = ApiJobsRepository(widget.services.api);
  JobsTab _tab = JobsTab.upcoming;

  Widget _list(BuildContext context, JobsTab tab) => BlocProvider(
    key: ValueKey(tab),
    create: (_) =>
        PagedCubit<BookingSummary>((cursor) => _repo.list(tab, cursor: cursor))
            .loading(),
    child: PagedView<BookingSummary>(
      itemBuilder: (_, job) => JobRow(job: job),
      empty: PaoEmptyState(
        title: tab == JobsTab.upcoming
            ? context.t.jobsEmptyUpcoming
            : context.t.jobsEmptyPast,
        message: context.t.jobsEmptyBody,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PaoAppBar(title: context.t.jobsTitle),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PaoSpace.lg,
            PaoSpace.md,
            PaoSpace.lg,
            0,
          ),
          child: PaoSegmented<JobsTab>(
            segments: {
              JobsTab.upcoming: context.t.jobsUpcoming,
              JobsTab.past: context.t.jobsPast,
            },
            selected: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
        Expanded(child: _list(context, _tab)),
      ],
    ),
  );
}

/// One job in the M23 list.
class JobRow extends StatelessWidget {
  /// Creates the row.
  const JobRow({required this.job, super.key});

  /// The job.
  final BookingSummary job;

  @override
  Widget build(BuildContext context) {
    final customer = job.counterpartName?.split(' ').first;
    final at = context.when(job.scheduledAt ?? job.createdAt, 'd MMM, h:mm a');
    return PaoListRow(
      title: context.local(job.serviceName),
      subtitle: customer == null ? at : '$customer · $at',
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PaoMoneyText(job.total),
          PaoBadge(
            label: statusLabel(context.t, job.status),
            tone: statusTone(job.status),
          ),
        ],
      ),
      onTap: () => context.push(Routes.job(job.id)),
    );
  }
}
