import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/delivery/data/delivery_repository.dart';
import 'package:pao_partner/features/delivery/presentation/order_view.dart';
import 'package:pao_partner/features/job/presentation/reason_sheet.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One scheduled-delivery order: accept or decline it, and decline single
/// dates before their cutoff (P25).
class OrderPage extends StatelessWidget {
  /// Creates the page for order [subscriptionId].
  const OrderPage({
    required this.services,
    required this.subscriptionId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The order.
  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    final repo = DeliveryRepository(services.api);
    final id = subscriptionId;
    return BlocProvider(
      create: (_) =>
          LoadCubit<Subscription>(() => repo.subscription(id))..load().ignore(),
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.ordersTitle),
        body: BlocBuilder<LoadCubit<Subscription>, ViewState<Subscription>>(
          builder: (context, state) => ViewStateView<Subscription>(
            state: state,
            onRetry: context.read<LoadCubit<Subscription>>().load,
            builder: (context, s) => OrderView(
              subscription: s,
              onAccept: () => _act(context, repo.accept(id)),
              onDecline: () => _decline(context, repo),
              onDeclineDate: (date) =>
                  _act(context, repo.declineDate(id, date)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _decline(BuildContext context, DeliveryRepository repo) async {
    final t = context.t;
    final choice = await showReasonSheet(
      context,
      title: t.orderDeclineTitle,
      form: ReasonSheet(
        confirm: t.orderDecline,
        reasons: {
          RejectInputReasonEnum.busy: t.reqReasonBusy,
          RejectInputReasonEnum.tooFar: t.reqReasonTooFar,
          RejectInputReasonEnum.notMyService: t.reqReasonNotMyService,
          RejectInputReasonEnum.other: t.reqReasonOther,
        },
      ),
    );
    if (choice != null && context.mounted) {
      await _act(context, repo.decline(subscriptionId, choice.$1, choice.$2));
    }
  }

  /// Runs a change, then reloads the order or says why it failed.
  Future<void> _act(BuildContext context, Future<void> change) async {
    final cubit = context.read<LoadCubit<Subscription>>();
    final messenger = ScaffoldMessenger.of(context);
    final why = context.failureText(await attempt(() => change));
    if (why != null) messenger.showSnackBar(SnackBar(content: Text(why)));
    await cubit.refresh();
  }
}
