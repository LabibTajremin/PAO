import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/data/api_booking_repository.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';
import 'package:pao_customer/features/delivery/data/api_delivery_repository.dart';
import 'package:pao_customer/features/delivery/presentation/order_cubit.dart';
import 'package:pao_customer/features/delivery/presentation/order_form.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Orders a scheduled delivery (P25): the chosen items from the service page,
/// the provider, then how often, when and where.
class OrderPage extends StatelessWidget {
  /// Creates the page for [draft].
  const OrderPage({required this.services, required this.draft, super.key});

  /// App services.
  final AppServices services;

  /// The service, items and provider chosen before.
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PaoAppBar(title: context.t.orderTitle),
    body: BlocProvider(
      create: (_) => OrderCubit(
        ApiBookingRepository(services.api),
        ApiDeliveryRepository(services.api),
        draft,
        now: services.now,
      )..load().ignore(),
      child: BlocConsumer<OrderCubit, OrderState>(
        listenWhen: (a, b) => a.subscription == null && b.subscription != null,
        listener: (context, s) =>
            context.go(Routes.subscriptionOf(s.subscription!.id)),
        builder: (context, s) => ViewStateView<BookingOptions>(
          state: s.view,
          onRetry: context.read<OrderCubit>().load,
          builder: (_, options) =>
              OrderForm(state: s, options: options, draft: draft),
        ),
      ),
    ),
  );
}
