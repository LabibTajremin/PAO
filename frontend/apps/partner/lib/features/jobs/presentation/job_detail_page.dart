import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/jobs/data/api_jobs_repository.dart';
import 'package:pao_partner/features/jobs/presentation/job_detail_view.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_partner/shared/load_on_create.dart';
import 'package:pao_ui/pao_ui.dart';

/// One job: items, total, customer, area and timeline (M24).
class JobDetailPage extends StatelessWidget {
  /// Creates the page for [bookingId].
  const JobDetailPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The job.
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final repo = ApiJobsRepository(services.api);
    return BlocProvider(
      create: (_) => LoadCubit<Booking>(() => repo.job(bookingId)).loading(),
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.jobsDetailTitle),
        body: BlocBuilder<LoadCubit<Booking>, ViewState<Booking>>(
          builder: (context, state) => ViewStateView<Booking>(
            state: state,
            onRetry: context.read<LoadCubit<Booking>>().load,
            builder: (_, job) => JobDetailView(job: job, repo: repo),
          ),
        ),
      ),
    );
  }
}
