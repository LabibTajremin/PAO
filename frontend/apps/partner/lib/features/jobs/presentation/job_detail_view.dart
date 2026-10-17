import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';
import 'package:pao_partner/features/jobs/presentation/item_rows.dart';
import 'package:pao_partner/features/jobs/presentation/receipt_sheet.dart';
import 'package:pao_partner/features/jobs/presentation/status_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The loaded content of M24.
class JobDetailView extends StatelessWidget {
  /// Creates the view of [job].
  const JobDetailView({required this.job, required this.repo, super.key});

  /// The job.
  final Booking job;

  /// Loads the receipt.
  final JobsRepository repo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        _Summary(job: job),
        const SizedBox(height: PaoSpace.lg),
        Text(context.t.jobsItems, style: text.titleMedium),
        ItemRows(items: job.items, total: job.total),
        if (job.timeline.isNotEmpty) ...[
          const SizedBox(height: PaoSpace.lg),
          Text(context.t.jobsTimeline, style: text.titleMedium),
          PaoStatusStepper(
            steps: [
              for (final e in job.timeline)
                [
                  statusLabel(context.t, e.status),
                  context.when(e.at, 'd MMM, h:mm a'),
                ].join(' · '),
            ],
            current: job.timeline.length - 1,
          ),
        ],
        const SizedBox(height: PaoSpace.xl),
        ..._actions(context),
      ],
    );
  }

  List<Widget> _actions(BuildContext context) => [
    if (activeStatuses.contains(job.status))
      PaoButton(
        label: context.t.jobsOpenLive,
        onPressed: () => context.push(Routes.job(job.id, 'live')),
      ),
    if (job.status == BookingStatus.completed)
      PaoButton(
        label: context.t.jobsReceipt,
        variant: PaoButtonVariant.soft,
        onPressed: () => showReceipt(context, repo, job.id),
      ),
    const SizedBox(height: PaoSpace.sm),
    PaoButton(
      label: context.t.jobsReport,
      variant: PaoButtonVariant.ghost,
      onPressed: () => context.push(Routes.job(job.id, 'report')),
    ),
  ];
}

class _Summary extends StatelessWidget {
  const _Summary({required this.job});

  final Booking job;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final customer = job.customer?.name.split(' ').first;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.local(job.serviceName),
                  style: text.titleLarge,
                ),
              ),
              PaoBadge(
                label: statusLabel(context.t, job.status),
                tone: statusTone(job.status),
              ),
            ],
          ),
          Text(job.number, style: text.bodySmall),
          const SizedBox(height: PaoSpace.md),
          Text(context.when(job.scheduledAt ?? job.createdAt)),
          if (customer != null) Text(context.t.jobsCustomer(customer)),
          Text(context.t.jobsArea(job.address.area)),
        ],
      ),
    );
  }
}
