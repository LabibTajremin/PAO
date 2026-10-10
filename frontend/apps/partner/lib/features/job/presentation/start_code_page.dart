import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/data/api_job_repository.dart';
import 'package:pao_partner/features/job/presentation/job_cubit.dart';
import 'package:pao_partner/shared/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The customer's 4-digit start code (M18, PRD §5 step 7).
class StartCodePage extends StatelessWidget {
  /// Creates the page.
  const StartCodePage({
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
    create: (_) => JobCubit(ApiJobRepository(services.api), bookingId),
    child: BlocConsumer<JobCubit, JobState>(
      listenWhen: (_, s) => s.done,
      listener: (context, _) => context.leave(Routes.job(bookingId, 'live')),
      builder: _content,
    ),
  );

  Widget _content(BuildContext context, JobState s) {
    final code = s.failure?.code;
    final locked = code == 'START_CODE_LOCKED';
    return Scaffold(
      appBar: PaoAppBar(title: context.t.jobStartTitle),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          Text(context.t.jobStartBody),
          const SizedBox(height: PaoSpace.xxl),
          if (!locked)
            PaoOtpInput(
              length: 4,
              semanticLabel: context.t.jobStartTitle,
              hasError: code == 'START_CODE_INVALID',
              onCompleted: context.read<JobCubit>().start,
            ),
          if (s.failure != null) ...[
            const SizedBox(height: PaoSpace.md),
            Text(
              context.failureText(s.failure)!,
              style: const TextStyle(color: PaoColors.danger),
            ),
          ],
          if (s.busy) ...[
            const SizedBox(height: PaoSpace.xl),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
