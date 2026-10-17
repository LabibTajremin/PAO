import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/jobs/data/api_jobs_repository.dart';
import 'package:pao_partner/features/jobs/presentation/report_cubit.dart';
import 'package:pao_partner/features/jobs/presentation/report_form.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Report a problem on a job (M25).
class ReportPage extends StatelessWidget {
  /// Creates the page for [bookingId].
  const ReportPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The job.
  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReportCubit(ApiJobsRepository(services.api), bookingId),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.jobsReportTitle),
      body: BlocBuilder<ReportCubit, ReportState>(
        buildWhen: (a, b) => a.ticket != b.ticket,
        builder: (context, s) => s.ticket == null
            ? ReportForm(photos: services.photos)
            : PaoMessageState(
                icon: Icons.check_circle_outline,
                title: context.t.jobsReportSent,
                message: context.t.jobsReportTicket(s.ticket!),
                action: PaoButton(
                  label: context.t.jobsBackToJob,
                  expand: false,
                  onPressed: () => context.go(Routes.job(bookingId)),
                ),
              ),
      ),
    ),
  );
}
