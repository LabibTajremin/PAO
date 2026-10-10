import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/features/requests/data/api_request_repository.dart';
import 'package:pao_partner/features/requests/presentation/request_body.dart';
import 'package:pao_partner/features/requests/presentation/request_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Full-screen incoming request with countdown, accept and reject (M16).
class RequestPage extends StatelessWidget {
  /// Creates the page.
  const RequestPage({
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
    create: (_) => RequestCubit(
      ApiRequestRepository(services.api),
      bookingId,
      now: services.now,
    )..load().ignore(),
    child: BlocConsumer<RequestCubit, RequestState>(
      listenWhen: (p, s) =>
          p.outcome != s.outcome && s.outcome != RequestOutcome.expired,
      listener: (context, s) => s.outcome == RequestOutcome.accepted
          ? context.pushReplacement(Routes.job(bookingId, 'live'))
          : context.leave(Routes.home),
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.reqTitle),
        body: s.outcome == RequestOutcome.expired
            ? _expired(context)
            : ViewStateView<Booking>(
                state: s.view,
                onRetry: context.read<RequestCubit>().load,
                builder: (_, b) => RequestBody(booking: b, state: s),
              ),
      ),
    ),
  );

  Widget _expired(BuildContext context) => PaoMessageState(
    icon: Icons.timer_off_outlined,
    title: context.t.reqExpiredTitle,
    message: context.t.reqExpiredBody,
    action: PaoButton(
      label: context.t.jobBackHome,
      expand: false,
      onPressed: () => context.go(Routes.home),
    ),
  );
}
