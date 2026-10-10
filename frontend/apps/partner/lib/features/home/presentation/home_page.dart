import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/home/data/api_home_repository.dart';
import 'package:pao_partner/features/home/data/prefs_online_memory.dart';
import 'package:pao_partner/features/home/domain/documents.dart';
import 'package:pao_partner/features/home/domain/heartbeat.dart';
import 'package:pao_partner/features/home/domain/home_repository.dart';
import 'package:pao_partner/features/home/presentation/home_feed.dart';
import 'package:pao_partner/features/home/presentation/presence_card.dart';
import 'package:pao_partner/features/home/presentation/presence_cubit.dart';
import 'package:pao_partner/shared/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The dashboard: online switch, today's earnings, the active job and open
/// requests (M15), or the paused state (M15b).
class HomePage extends StatelessWidget {
  /// Creates the page.
  const HomePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final repo = ApiHomeRepository(services.api);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LoadCubit<HomeSummary>(repo.summary)..load().ignore(),
        ),
        BlocProvider(
          create: (_) => PresenceCubit(
            repo,
            services.location,
            TimerHeartbeat(),
            PrefsOnlineMemory(services.prefs),
          )..resume().ignore(),
        ),
      ],
      child: Scaffold(
        appBar: PaoAppBar(
          title: context.common.navHome,
          actions: [
            IconButton(
              tooltip: context.common.navNotifications,
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(Routes.notifications),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: services.gate,
          builder: (context, _) => _body(
            context,
            documentNotice(services.gate.status, services.now()),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DocumentNotice notice) {
    final summary = context.read<LoadCubit<HomeSummary>>();
    final expires = notice.expiresAt;
    return RefreshIndicator(
      onRefresh: () => Future.wait([summary.refresh(), services.gate.load()]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(PaoSpace.lg),
        children: [
          if (expires != null)
            InkWell(
              onTap: () => context.push(Routes.profilePage('documents')),
              child: PaoBanner(
                icon: Icons.event_busy_outlined,
                message: context.t.homeExpiring(
                  formatDhaka(
                    expires,
                    pattern: 'd MMM y',
                    locale: context.lang,
                  ),
                ),
              ),
            ),
          const SizedBox(height: PaoSpace.md),
          BlocBuilder<PresenceCubit, OnlineState>(
            builder: (_, s) => PresenceCard(state: s, paused: notice.paused),
          ),
          const SizedBox(height: PaoSpace.lg),
          BlocBuilder<LoadCubit<HomeSummary>, ViewState<HomeSummary>>(
            builder: (_, s) => ViewStateView<HomeSummary>(
              state: s,
              onRetry: summary.load,
              builder: (_, data) => HomeFeed(summary: data),
            ),
          ),
        ],
      ),
    );
  }
}
