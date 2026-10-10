import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/jobs/presentation/formats.dart';
import 'package:pao_partner/features/jobs/presentation/load_on_create.dart';
import 'package:pao_partner/features/profile/data/api_profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/profile_labels.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The provider's badge and level, how each level is earned and Level 2
/// status (M32, PRD §6.1–6.3).
class LevelPage extends StatelessWidget {
  /// Creates the page.
  const LevelPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<VerificationStatus>(
      ApiProfileRepository(services.api).verification,
    ).loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.profLevelTitle),
      body:
          BlocBuilder<
            LoadCubit<VerificationStatus>,
            ViewState<VerificationStatus>
          >(
            builder: (context, state) => ViewStateView<VerificationStatus>(
              state: state,
              onRetry: context.read<LoadCubit<VerificationStatus>>().load,
              builder: (_, status) => _Levels(status: status),
            ),
          ),
    ),
  );
}

class _Levels extends StatelessWidget {
  const _Levels({required this.status});

  final VerificationStatus status;

  String _level2(BuildContext context) {
    final t = context.t;
    final info = status.level2;
    final session = info?.nextSession;
    final retry = info?.retryAfter;
    if (status.level >= 2) return t.profLevel2Done;
    if (session != null) {
      return t.profLevel2Session(
        context.when(session.scheduledAt),
        session.location,
      );
    }
    if (retry != null) return t.profLevel2Retry(context.when(retry, 'd MMM y'));
    if (info?.eligible ?? false) return t.profLevel2Eligible;
    return t.profLevel2NotYet;
  }

  Widget _current(BuildContext context) => PaoCard(
    highlighted: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.profLevelOf(
            context.count(status.level),
            levelName(context.t, status.level),
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: PaoSpace.sm),
        PaoBadge(
          label: badgeLabel(context.t, status.badge),
          tone: badgeTone(status.badge),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    final explained = [
      (t.profLevel0, t.profLevel0How),
      (t.profLevel1, t.profLevel1How),
      (t.profLevel2, t.profLevel2How),
    ];
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        _current(context),
        const SizedBox(height: PaoSpace.lg),
        for (final (i, (name, how)) in explained.indexed)
          PaoListRow(
            leading: Icon(
              i <= status.level ? Icons.check_circle : Icons.circle_outlined,
              color: context.pao.accent.primary,
            ),
            title: t.profLevelOf(context.count(i), name),
            subtitle: how,
          ),
        const SizedBox(height: PaoSpace.lg),
        Text(t.profLevel2Title, style: text.titleMedium),
        const SizedBox(height: PaoSpace.sm),
        Text(_level2(context)),
      ],
    );
  }
}
