import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/data/api_job_repository.dart';
import 'package:pao_partner/features/job/presentation/job_cubit.dart';
import 'package:pao_partner/features/job/presentation/job_items.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Final bill and cash received (M20); payment is cash only in the MVP (D4).
class CompletePage extends StatefulWidget {
  /// Creates the page.
  const CompletePage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  State<CompletePage> createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  bool _cash = false;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        JobCubit(ApiJobRepository(widget.services.api), widget.bookingId)
          ..load().ignore(),
    child: BlocConsumer<JobCubit, JobState>(
      listenWhen: (_, s) => s.done,
      listener: (context, _) =>
          context.pushReplacement(Routes.job(widget.bookingId, 'rate')),
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.jobCompleteTitle),
        body: ViewStateView<Booking>(
          state: s.view,
          onRetry: context.read<JobCubit>().load,
          builder: (context, b) => _bill(context, b, s),
        ),
      ),
    ),
  );

  Widget _bill(BuildContext context, Booking b, JobState s) => ListView(
    padding: const EdgeInsets.all(PaoSpace.lg),
    children: [
      JobItems(items: b.items, total: b.total),
      const SizedBox(height: PaoSpace.lg),
      CheckboxListTile(
        value: _cash,
        onChanged: (v) => setState(() => _cash = v!),
        title: Text(
          context.t.jobCashReceived(formatMoney(b.total, locale: context.lang)),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      if (s.failure != null)
        Text(
          context.failureText(s.failure)!,
          style: const TextStyle(color: PaoColors.danger),
        ),
      const SizedBox(height: PaoSpace.lg),
      PaoButton(
        label: context.t.jobActionComplete,
        loading: s.busy,
        onPressed: _cash ? context.read<JobCubit>().complete : null,
      ),
    ],
  );
}
