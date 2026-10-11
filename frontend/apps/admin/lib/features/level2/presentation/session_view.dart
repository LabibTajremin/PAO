import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/level2/presentation/level2_labels.dart';
import 'package:pao_admin/features/level2/presentation/result_form.dart';
import 'package:pao_admin/features/level2/presentation/session_cubit.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Session [id] in the side drawer (`showDetailDrawer`); [onRecorded] runs
/// once a result is saved so the list behind can refresh.
class SessionPanel extends StatelessWidget {
  /// Creates the panel.
  const SessionPanel({
    required this.repo,
    required this.id,
    required this.canRecord,
    required this.onRecorded,
    super.key,
  });

  /// Where the session comes from.
  final Level2Repository repo;

  /// Session ID.
  final String id;

  /// The admin may record results.
  final bool canRecord;

  /// Runs after a result is saved.
  final VoidCallback onRecorded;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = SessionCubit(repo, id);
      unawaited(cubit.load());
      return cubit;
    },
    child: SessionView(canRecord: canRecord, onRecorded: onRecorded),
  );
}

/// A session's facts, then the result form while it is open or the recorded
/// result once it is closed.
class SessionView extends StatelessWidget {
  /// Creates the view.
  const SessionView({
    required this.canRecord,
    required this.onRecorded,
    super.key,
  });

  /// The admin may record results.
  final bool canRecord;

  /// Runs after a result is saved.
  final VoidCallback onRecorded;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SessionCubit, SessionState>(
        listenWhen: (before, now) => now.recorded && !before.recorded,
        listener: (_, _) => onRecorded(),
        builder: (context, s) => ViewStateView<SessionDetail>(
          state: s.view,
          onRetry: context.read<SessionCubit>().load,
          builder: (context, detail) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PaoSpace.md,
            children: [
              _Facts(row: detail.row),
              const Divider(),
              if (detail.row.session.status !=
                  Level2SessionStatusEnum.scheduled)
                _Outcome(session: detail.row.session)
              else if (canRecord)
                ResultForm(
                  template: [for (final i in detail.template) context.local(i)],
                  busy: s.busy,
                  error: context.level2Failure(s.failure),
                  onSubmit: context.read<SessionCubit>().record,
                ),
            ],
          ),
        ),
      );
}

class _Facts extends StatelessWidget {
  const _Facts({required this.row});

  final Level2Row row;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = row.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PaoSpace.sm,
      children: [
        Text(
          context.providerOf(row),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(context.serviceOf(row)),
        Text('${t.level2ColWhen}: ${context.when(s.scheduledAt)}'),
        Text('${t.level2Location}: ${s.location}'),
        PaoBadge(label: sessionStatusLabel(t, s.status)),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.session});

  final Level2Session session;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final result = session.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PaoSpace.sm,
      children: [
        if (result != null)
          PaoBadge(label: resultLabel(t, result), tone: resultTone(result)),
        for (final c
            in session.checklist ?? const <Level2SessionChecklistInner>[])
          Row(
            spacing: PaoSpace.sm,
            children: [
              Icon(
                c.passed ? Icons.check_circle : Icons.cancel,
                color: c.passed ? PaoColors.success : PaoColors.danger,
              ),
              Expanded(child: Text(c.item)),
            ],
          ),
        if (session.notes case final notes? when notes.isNotEmpty)
          Text('${t.level2Notes}: $notes'),
      ],
    );
  }
}
