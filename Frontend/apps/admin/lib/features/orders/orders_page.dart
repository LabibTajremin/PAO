import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/orders/order_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Scheduled-delivery orders in the bookings monitor (ADR-0041), newest
/// first, filtered by status.
class OrdersPage extends StatefulWidget {
  /// Creates the page.
  const OrdersPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  SubscriptionStatus? _status;

  Future<List<Subscription>> _load() async =>
      (await AdminBookingsApi(widget.services.api)
              .listAdminSubscriptions(status: _status))
          .data!
          .items;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider(
      key: ValueKey(_status),
      create: (_) => LoadCubit<List<Subscription>>(_load)..load().ignore(),
      child: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          ListHeading(t.ordersTitle),
          Wrap(
            spacing: PaoSpace.sm,
            children: [
              PaoChip(
                label: t.ordersAll,
                selected: _status == null,
                onTap: () => setState(() => _status = null),
              ),
              for (final s in SubscriptionStatus.values)
                PaoChip(
                  label: subscriptionStatus(t, s).$1,
                  selected: _status == s,
                  onTap: () => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: PaoSpace.lg),
          BlocBuilder<
            LoadCubit<List<Subscription>>,
            ViewState<List<Subscription>>
          >(
            builder: (context, state) => ViewStateView<List<Subscription>>(
              state: state,
              onRetry: context.read<LoadCubit<List<Subscription>>>().load,
              isEmpty: (list) => list.isEmpty,
              empty: PaoEmptyState(title: t.ordersEmpty),
              builder: (context, list) =>
                  Column(children: [for (final o in list) _Row(o)]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.o);

  final Subscription o;

  @override
  Widget build(BuildContext context) {
    final (status, tone) = subscriptionStatus(context.t, o.status);
    return PaoListRow(
      title: '${o.number} · ${context.local(o.serviceName)}',
      subtitle: [
        o.customer?.name,
        o.provider?.name,
        o.address.area,
      ].whereType<String>().join(' · '),
      trailing: PaoBadge(label: status, tone: tone),
      onTap: () => context.go(Routes.detail(Routes.orders, o.id)),
    );
  }
}
