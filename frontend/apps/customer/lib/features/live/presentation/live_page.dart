import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart'
    show Booking, BookingStatus, ExtrasProposalStatusEnum;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/presentation/track_cubit.dart';
import 'package:pao_customer/features/connectivity/data/start_code_cache.dart';
import 'package:pao_customer/features/live/data/api_live_repository.dart';
import 'package:pao_customer/features/live/presentation/live_body.dart';
import 'package:pao_customer/features/live/presentation/live_sections.dart';
import 'package:pao_customer/features/live/presentation/start_code_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The active booking (C49 accepted, C14 on the way, C50 arrived, C51 in
/// progress): status, provider, start code, extras and cancel.
class LivePage extends StatelessWidget {
  /// Creates the page.
  const LivePage({required this.services, required this.bookingId, super.key});

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final repo = ApiLiveRepository(services.api);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              TrackCubit(repo, bookingId, now: services.now)..load().ignore(),
        ),
        BlocProvider(
          create: (_) =>
              StartCodeCubit(repo, StartCodeCache(services.prefs), bookingId)
                ..load().ignore(),
        ),
      ],
      child: BlocConsumer<TrackCubit, TrackState>(
        listenWhen: (a, b) =>
            a.booking?.status != b.booking?.status ||
            _target(a.booking) != _target(b.booking),
        listener: _follow,
        builder: (context, s) => Scaffold(
          appBar: PaoAppBar(title: context.t.liveTitle),
          body: _body(context, s),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TrackState s) {
    final cubit = context.read<TrackCubit>();
    final cached = context.watch<StartCodeCubit>().state.code;
    if (s.view is ViewFailure<Booking> && cached != null) {
      return OfflineCodeView(onRetry: cubit.load);
    }
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ViewStateView<Booking>(
        state: s.view,
        onRetry: cubit.load,
        builder: (_, b) => LiveBody(state: s, services: services),
      ),
    );
  }

  Future<void> _follow(BuildContext context, TrackState s) async {
    final b = s.booking;
    if (b == null) return;
    final codes = context.read<StartCodeCubit>();
    final track = context.read<TrackCubit>();
    await codes.sync(b.status);
    final target = _target(b);
    if (target == null || !context.mounted) return;
    if (target.startsWith('extras')) {
      await context.push(Routes.booking(b.id, 'extras'));
      await track.refresh();
    } else {
      context.go(Routes.booking(b.id, target));
    }
  }
}

// Where the booking's status sends the customer: back to waiting while it is
// unanswered, to the bill once done, and to approval for new extras. The
// proposal ID makes each new proposal open the approval screen once.
String? _target(Booking? b) {
  final pending = b?.pendingExtras;
  return switch (b?.status) {
    BookingStatus.requested ||
    BookingStatus.rejected ||
    BookingStatus.timedOut => 'waiting',
    BookingStatus.completed => 'completed',
    BookingStatus.inProgress
        when pending?.status == ExtrasProposalStatusEnum.pending =>
      'extras#${pending!.id}',
    _ => null,
  };
}
