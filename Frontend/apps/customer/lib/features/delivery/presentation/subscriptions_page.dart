import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/delivery/data/api_delivery_repository.dart';
import 'package:pao_customer/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The customer's scheduled-delivery orders, newest first (P25).
class SubscriptionsPage extends StatelessWidget {
  /// Creates the page.
  const SubscriptionsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        LoadCubit<List<Subscription>>(ApiDeliveryRepository(services.api).list)
          ..load().ignore(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.ordersTitle),
      body:
          BlocBuilder<
            LoadCubit<List<Subscription>>,
            ViewState<List<Subscription>>
          >(
            builder: (context, state) => ViewStateView<List<Subscription>>(
              state: state,
              onRetry: context.read<LoadCubit<List<Subscription>>>().load,
              isEmpty: (list) => list.isEmpty,
              empty: PaoEmptyState(
                title: context.t.ordersEmpty,
                illustration: const ScopedArtwork('empty.bookings'),
              ),
              builder: (context, list) => ListView(
                padding: const EdgeInsets.all(PaoSpace.lg),
                children: [for (final s in list) SubscriptionCard(s)],
              ),
            ),
          ),
    ),
  );
}

/// One order in the list: the service, how often and its status.
class SubscriptionCard extends StatelessWidget {
  /// Creates the card.
  const SubscriptionCard(this.subscription, {super.key});

  /// The order.
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = subscription;
    final (status, tone) = subscriptionStatus(t, s.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        onTap: () => context.push(Routes.subscriptionOf(s.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaoListRow(
              title: context.local(s.serviceName),
              subtitle:
                  '${patternLabel(t, s.pattern)} · '
                  '${s.window.start}–${s.window.end} · ${s.number}',
            ),
            // Below the text, so a long status never squeezes the name.
            PaoBadge(label: status, tone: tone),
          ],
        ),
      ),
    );
  }
}
