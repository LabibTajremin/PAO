import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/billing/data/api_billing_repository.dart';
import 'package:pao_partner/features/billing/presentation/billing_rows.dart';
import 'package:pao_partner/features/billing/presentation/due_summary_card.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Which history the billing screen lists.
enum BillingTab {
  /// Commission debits and payment credits.
  ledger,

  /// Reported payments and their review.
  payments,
}

/// The due to PAO, the ledger and the payment history (ADR-0035).
class BillingPage extends StatefulWidget {
  /// Creates the page.
  const BillingPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late final LoadCubit<DueSummary> _due;
  late final PagedCubit<LedgerEntry> _ledger;
  late final PagedCubit<PaymentSubmission> _payments;
  BillingTab _tab = BillingTab.ledger;

  // Built eagerly: a lazy `late` cubit would first be created, and load, in
  // dispose.
  @override
  void initState() {
    super.initState();
    final repo = ApiBillingRepository(widget.services.api);
    _due = LoadCubit<DueSummary>(repo.due).loading();
    _ledger = PagedCubit((c) => repo.ledger(cursor: c)).loading();
    _payments = PagedCubit((c) => repo.payments(cursor: c)).loading();
  }

  @override
  void dispose() {
    _due.close().ignore();
    _ledger.close().ignore();
    _payments.close().ignore();
    super.dispose();
  }

  Future<void> _pay() async {
    await context.push(Routes.pay);
    await Future.wait([_due.refresh(), _payments.load()]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider.value(
      value: _due,
      child: Scaffold(
        appBar: PaoAppBar(title: t.billTitle),
        body: _tab == BillingTab.ledger
            ? BlocProvider.value(
                value: _ledger,
                child: PagedView<LedgerEntry>(
                  header: _header(context),
                  itemBuilder: (_, e) => LedgerRow(entry: e),
                  empty: PaoEmptyState(
                    title: t.billLedgerEmpty,
                    message: t.billLedgerEmptyBody,
                  ),
                ),
              )
            : BlocProvider.value(
                value: _payments,
                child: PagedView<PaymentSubmission>(
                  header: _header(context),
                  itemBuilder: (_, p) => PaymentRow(payment: p),
                  empty: PaoEmptyState(
                    title: t.billPaymentsEmpty,
                    message: t.billPaymentsEmptyBody,
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _header(BuildContext context) {
    final t = context.t;
    return [
      BlocBuilder<LoadCubit<DueSummary>, ViewState<DueSummary>>(
        builder: (_, s) => ViewStateView<DueSummary>(
          state: s,
          onRetry: _due.load,
          builder: (_, due) => DueSummaryCard(due: due),
        ),
      ),
      const SizedBox(height: PaoSpace.md),
      PaoButton(label: t.billPayNow, onPressed: _pay),
      const SizedBox(height: PaoSpace.lg),
      PaoSegmented<BillingTab>(
        segments: {
          BillingTab.ledger: t.billLedger,
          BillingTab.payments: t.billPayments,
        },
        selected: _tab,
        onChanged: (tab) => setState(() => _tab = tab),
      ),
      const SizedBox(height: PaoSpace.md),
    ];
  }
}
