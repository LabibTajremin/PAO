import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/presentation/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The period total and its per-day breakdown (M26).
class EarningsSummaryCard extends StatelessWidget {
  /// Creates the card over the nearest summary cubit.
  const EarningsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LoadCubit<EarningsSummary>, ViewState<EarningsSummary>>(
        builder: (context, state) => ViewStateView<EarningsSummary>(
          state: state,
          onRetry: context.read<LoadCubit<EarningsSummary>>().load,
          builder: (_, summary) => _Summary(summary: summary),
        ),
      );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final range = summary.from == summary.to
        ? context.day(summary.from)
        : '${context.day(summary.from, 'd MMM')} – ${context.day(summary.to)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaoCard(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(range, style: text.bodySmall),
              PaoMoneyText(summary.total, style: text.headlineMedium),
              Text(
                context.t.earnJobs(summary.jobs, context.count(summary.jobs)),
              ),
            ],
          ),
        ),
        // A single day has nothing to break down.
        if (summary.buckets.length > 1)
          for (final bucket in summary.buckets)
            PaoListRow(
              title: context.day(bucket.date, 'EEE, d MMM'),
              subtitle: context.t.earnJobs(
                bucket.jobs,
                context.count(bucket.jobs),
              ),
              trailing: PaoMoneyText(bucket.total),
            ),
      ],
    );
  }
}
