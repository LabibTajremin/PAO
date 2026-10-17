import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking, BookingStatus;
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/data/api_job_repository.dart';
import 'package:pao_partner/features/job/presentation/job_cubit.dart';
import 'package:pao_partner/features/job/presentation/live_job_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The active job: status actions, directions, call and cancel (M17).
class LiveJobPage extends StatelessWidget {
  /// Creates the page.
  const LiveJobPage({
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
        JobCubit(ApiJobRepository(services.api), bookingId)..load().ignore(),
    child: BlocConsumer<JobCubit, JobState>(
      listenWhen: (_, s) =>
          s.done && s.booking?.status == BookingStatus.cancelled,
      listener: (context, _) => context.go(Routes.home),
      builder: (context, s) {
        final cubit = context.read<JobCubit>();
        return Scaffold(
          appBar: PaoAppBar(title: context.t.jobLiveTitle),
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ViewStateView<Booking>(
              state: s.view,
              onRetry: cubit.load,
              builder: (_, _) =>
                  LiveJobBody(state: s, launcher: services.launcher),
            ),
          ),
        );
      },
    ),
  );
}
