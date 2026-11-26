import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/delivery/data/api_delivery_repository.dart';
import 'package:pao_customer/features/delivery/domain/delivery_repository.dart';
import 'package:pao_customer/features/delivery/presentation/subscription_view.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One scheduled-delivery order: its next dates, skipping one, pausing,
/// resuming and cancelling (P25).
class SubscriptionPage extends StatelessWidget {
  /// Creates the page for order [subscriptionId].
  const SubscriptionPage({
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
    final repo = ApiDeliveryRepository(services.api);
    return BlocProvider(
      create: (_) =>
          LoadCubit<Subscription>(() => repo.subscription(subscriptionId))
            ..load().ignore(),
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.ordersTitle),
        body: BlocBuilder<LoadCubit<Subscription>, ViewState<Subscription>>(
          builder: (context, state) => ViewStateView<Subscription>(
            state: state,
            onRetry: context.read<LoadCubit<Subscription>>().load,
            builder: (context, s) => SubscriptionView(
              subscription: s,
              onAct: (act) => _act(context, act(repo)),
            ),
          ),
        ),
      ),
    );
  }

  /// Runs a change, then reloads the order or says why it failed.
  Future<void> _act(BuildContext context, Future<void> change) async {
    final cubit = context.read<LoadCubit<Subscription>>();
    final messenger = ScaffoldMessenger.of(context);
    final why = context.failureText(await attempt(() => change));
    if (why != null) {
      messenger.showSnackBar(SnackBar(content: Text(why)));
    }
    await cubit.refresh();
  }
}

/// A change to an order, run against the repository.
typedef OrderAct = Future<void> Function(DeliveryRepository repo);
