import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/features/orders/order_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// One scheduled-delivery order for support: both parties, the plan and the
/// next dates, each booked date linked to its booking.
class OrderDetailPage extends StatelessWidget {
  /// Creates the page for order [id].
  const OrderDetailPage({required this.services, required this.id, super.key});

  /// App services.
  final AppServices services;

  /// The order.
  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<Subscription>(
      () async =>
          (await AdminBookingsApi(services.api)
                  .getAdminSubscription(subscriptionId: id))
              .data!,
    )..load().ignore(),
    child: BlocBuilder<LoadCubit<Subscription>, ViewState<Subscription>>(
      builder: (context, state) => ViewStateView<Subscription>(
        state: state,
        onRetry: context.read<LoadCubit<Subscription>>().load,
        builder: (context, o) => _Detail(o),
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.o);

  final Subscription o;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (status, tone) = subscriptionStatus(t, o.status);
    String party(BookingParty? p) =>
        [p?.name, p?.phone].whereType<String>().join(' · ');
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        ListHeading(
          '${o.number} · ${context.local(o.serviceName)}',
          trailing: PaoBadge(label: status, tone: tone),
        ),
        Text(
          '${patternLabel(t, o.pattern)} · ${o.window.start}–${o.window.end}',
        ),
        Text(party(o.customer)),
        Text(party(o.provider)),
        Text([o.address.area, o.address.line1].whereType<String>().join(' · ')),
        PaoMoneyText(o.total),
        const SizedBox(height: PaoSpace.lg),
        Text(t.ordersUpcoming, style: Theme.of(context).textTheme.titleSmall),
        for (final d in o.upcoming ?? const <DeliveryDate>[])
          PaoListRow(
            title: context.day(d.date),
            subtitle: deliveryStatus(t, d.status),
            onTap: switch (d.bookingId) {
              final booking? => () => context.go(
                Routes.detail(Routes.bookings, booking),
              ),
              null => null,
            },
          ),
      ],
    );
  }
}
