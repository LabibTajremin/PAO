import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/billing/domain/billing_repository.dart';
import 'package:pao_admin/features/billing/presentation/billing_labels.dart';
import 'package:pao_admin/features/billing/presentation/payment_dialog.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/confirm_reason.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/filtered_paged_cubit.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/filter_menu.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

typedef _Cubit =
    FilteredPagedCubit<PaymentSubmission, PaymentSubmissionStatus?>;

/// Payments merchants reported, pending first, to confirm or reject
/// (ADR-0035 §4).
class PaymentsPage extends StatefulWidget {
  /// Creates the page.
  const PaymentsPage({required this.repo, super.key});

  /// Payments and ledgers.
  final BillingRepository repo;

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late final _Cubit _cubit = _Cubit(
    PaymentSubmissionStatus.pending,
    widget.repo.payments,
  ).loading();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  List<AdminColumn<PaymentSubmission>> _columns(AdminL10n t) => [
    AdminColumn(t.payMerchant, (p) => Text(shortId(p.providerId))),
    AdminColumn(t.payAmount, (p) => PaoMoneyText(p.amount)),
    AdminColumn(t.payMethod, (p) => Text(paymentMethodLabel(t, p.method))),
    AdminColumn(t.payReference, (p) => Text(p.reference), flex: 2),
    AdminColumn(
      t.peopleFilterStatus,
      (p) => StatusCell(
        label: paymentStatusLabel(t, p.status),
        tone: paymentStatusTone(p.status),
      ),
      flex: 2,
    ),
    AdminColumn(
      t.paySubmitted,
      (p) => Text(context.when(p.createdAt, 'd MMM, h:mm a')),
      flex: 2,
    ),
  ];

  Future<void> _open(PaymentSubmission p) async {
    final action = await showPaymentDialog(context, p);
    if (!mounted || action == null) return;
    final t = context.t;
    if (action == PaymentAction.ledger) {
      return context.go(Routes.ledgerOf(p.providerId));
    }
    final reason = action == PaymentAction.reject
        ? await confirmWithReason(
            context,
            title: t.payRejectTitle,
            confirmLabel: t.payReject,
            minLength: rejectReasonLength.min,
            maxLength: rejectReasonLength.max,
          )
        : null;
    if (action == PaymentAction.reject && reason == null) return;
    final failure = await attempt(
      () => reason == null
          ? widget.repo.confirm(p.id)
          : widget.repo.reject(p.id, reason),
    );
    if (!mounted) return;
    final done = reason == null ? t.payConfirmed : t.payRejected;
    showDone(context, context.failureText(failure) ?? done);
    await _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider<PagedCubit<PaymentSubmission>>.value(
      value: _cubit,
      child: PagedTable<PaymentSubmission>(
        header: [
          ListHeading(t.payTitle),
          BlocBuilder<_Cubit, PagedState<PaymentSubmission>>(
            bloc: _cubit,
            builder: (context, _) => FilterBar(
              filters: [
                FilterMenu<PaymentSubmissionStatus>(
                  label: t.peopleFilterStatus,
                  options: paymentStatusOptions(t),
                  value: _cubit.filter,
                  onChanged: _cubit.apply,
                ),
              ],
            ),
          ),
        ],
        columns: _columns(t),
        empty: PaoEmptyState(title: t.payEmpty),
        onOpen: _open,
      ),
    );
  }
}
