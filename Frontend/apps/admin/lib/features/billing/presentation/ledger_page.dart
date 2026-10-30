import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/billing/domain/billing_repository.dart';
import 'package:pao_admin/features/billing/presentation/billing_labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// One merchant's due and ledger: commissions and confirmed payments.
class LedgerPage extends StatefulWidget {
  /// Creates the page for merchant [providerId].
  const LedgerPage({required this.repo, required this.providerId, super.key});

  /// Payments and ledgers.
  final BillingRepository repo;

  /// The merchant.
  final String providerId;

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  // Every page carries the summary; the latest one is shown.
  final _summary = ValueNotifier<DueSummary?>(null);
  late final PagedCubit<LedgerEntry> _cubit = PagedCubit<LedgerEntry>((
    cursor,
  ) async {
    final page = await widget.repo.ledger(widget.providerId, cursor);
    _summary.value = page.summary;
    return page.entries;
  }).loading();

  @override
  void dispose() {
    unawaited(_cubit.close());
    _summary.dispose();
    super.dispose();
  }

  List<AdminColumn<LedgerEntry>> _columns(AdminL10n t) => [
    AdminColumn(
      t.ledgerKind,
      (e) => Text(
        e.kind == LedgerEntryKindEnum.commission
            ? t.ledgerCommission(e.bookingNumber ?? '')
            : t.ledgerPayment,
      ),
      flex: 2,
    ),
    AdminColumn(t.payAmount, (e) => _Amount(entry: e)),
    AdminColumn(
      t.ledgerJobTotal,
      (e) => Text(switch (e.jobTotal) {
        final total? => context.money(total),
        null => '—',
      }),
    ),
    AdminColumn(t.ledgerDate, (e) => Text(context.when(e.createdAt)), flex: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider.value(
      value: _cubit,
      child: PagedTable<LedgerEntry>(
        header: [
          BackLink(label: t.ledgerBack, to: Routes.payments),
          ListHeading(t.ledgerTitle),
          ValueListenableBuilder(
            valueListenable: _summary,
            builder: (context, due, _) =>
                due == null ? const SizedBox.shrink() : _Summary(due: due),
          ),
        ],
        columns: _columns(t),
        empty: PaoEmptyState(title: t.ledgerEmpty),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final debit = entry.kind == LedgerEntryKindEnum.commission;
    return Text(
      '${debit ? '+' : '−'}${context.money(entry.amount)}',
      style: TextStyle(color: debit ? PaoColors.danger : null),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.due});

  final DueSummary due;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Section(
      title: t.ledgerDue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCell(
            label: due.blocked ? t.ledgerBlocked : t.ledgerClear,
            tone: due.blocked ? PaoTone.danger : PaoTone.success,
          ),
          Fact(t.ledgerDue, context.money(due.due)),
          Fact(t.ledgerLimit, context.money(due.blockAmount)),
          Fact(t.ledgerPending, context.money(due.pendingPayments)),
          Fact(t.ledgerRate, '${percentOf(due.commissionRateBp)}%'),
        ],
      ),
    );
  }
}
