import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/delivery/data/delivery_repository.dart';
import 'package:pao_partner/features/delivery/presentation/delivery_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

enum _Tab { orders, week }

/// The merchant's scheduled deliveries (P25): new orders to answer and this
/// week's deliveries, by date and window.
class OrdersPage extends StatefulWidget {
  /// Creates the page.
  const OrdersPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  _Tab _tab = _Tab.orders;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final repo = DeliveryRepository(widget.services.api);
    final today = widget.services.now();
    String day(int add) =>
        DateFormat('yyyy-MM-dd')
            .format(DateTime(today.year, today.month, today.day + add));
    return Scaffold(
      appBar: PaoAppBar(title: t.ordersTitle),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(PaoSpace.lg),
            child: PaoSegmented<_Tab>(
              segments: {
                _Tab.orders: t.ordersNew,
                _Tab.week: t.ordersDeliveries,
              },
              selected: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _Tab.orders => _Loaded<Subscription>(
                key: const ValueKey(_Tab.orders),
                load: () => repo.list(SubscriptionStatus.requested),
                empty: t.ordersNoNew,
                item: _OrderRow.new,
              ),
              _Tab.week => _Loaded<ProviderDelivery>(
                key: const ValueKey(_Tab.week),
                load: () => repo.deliveries(day(0), day(6)),
                empty: t.ordersNoDeliveries,
                item: _DeliveryRow.new,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Loaded<E> extends StatelessWidget {
  const _Loaded({
    required this.load,
    required this.empty,
    required this.item,
    super.key,
  });

  final Future<List<E>> Function() load;
  final String empty;
  final Widget Function(E) item;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<List<E>>(load)..load().ignore(),
    child: BlocBuilder<LoadCubit<List<E>>, ViewState<List<E>>>(
      builder: (context, state) => ViewStateView<List<E>>(
        state: state,
        onRetry: context.read<LoadCubit<List<E>>>().load,
        isEmpty: (list) => list.isEmpty,
        empty: PaoEmptyState(
          title: empty,
          illustration: const ScopedArtwork('empty.jobs'),
        ),
        builder: (_, list) =>
            ListView(children: [for (final x in list) item(x)]),
      ),
    ),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow(this.s);

  final Subscription s;

  @override
  Widget build(BuildContext context) => PaoListRow(
    title: context.local(s.serviceName),
    subtitle:
        '${patternLabel(context.t, s.pattern)} · '
        '${s.window.start}–${s.window.end} · ${s.address.area}',
    onTap: () => context.push(Routes.orderOf(s.id)),
  );
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow(this.d);

  final ProviderDelivery d;

  @override
  Widget build(BuildContext context) {
    final (status, tone) = deliveryStatus(context.t, d.status);
    final booking = d.bookingId;
    return PaoListRow(
      title:
          '${context.day(d.date, 'EEE, d MMM')} · '
          '${d.window.start}–${d.window.end}',
      subtitle:
          '${context.local(d.serviceName)} · ${d.customerName ?? ''} · '
          '${d.address.area}',
      trailing: PaoBadge(label: status, tone: tone),
      onTap: () => context.push(
        booking == null
            ? Routes.orderOf(d.subscriptionId)
            : Routes.job(booking),
      ),
    );
  }
}
