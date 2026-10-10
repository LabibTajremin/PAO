import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/data/api_booking_repository.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/presentation/bill.dart';
import 'package:pao_customer/features/booking/presentation/provider_card.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A scheduled booking the provider accepted (C48).
class ConfirmedPage extends StatelessWidget {
  /// Creates the page.
  const ConfirmedPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<Booking>(
      () => ApiBookingRepository(services.api).booking(bookingId),
    ).loading(),
    child: BlocBuilder<LoadCubit<Booking>, ViewState<Booking>>(
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.bookingConfirmedTitle),
        body: ViewStateView<Booking>(
          state: s,
          onRetry: context.read<LoadCubit<Booking>>().load,
          builder: (_, b) => _Body(booking: b, services: services),
        ),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.booking, required this.services});

  final Booking booking;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final provider = b.provider;
    final phone = provider?.phone;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        ..._heading(context),
        const SizedBox(height: PaoSpace.xl),
        if (provider != null)
          PartyCard.party(
            provider,
            onCall: phone == null ? null : () => services.launcher.call(phone),
          ),
        const SizedBox(height: PaoSpace.md),
        BillView(
          title: context.local(b.serviceName),
          lines: [for (final item in b.items) BillLine.of(item)],
          total: b.total,
        ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: context.t.bookingConfirmedView,
          onPressed: () => context.push(Routes.booking(b.id)),
        ),
        PaoButton(
          label: context.t.bookingBackHome,
          variant: PaoButtonVariant.ghost,
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }

  List<Widget> _heading(BuildContext context) {
    final at = booking.scheduledAt;
    return [
      Icon(Icons.event_available, size: 64, color: context.pao.accent.primary),
      const SizedBox(height: PaoSpace.md),
      Text(
        context.t.bookingConfirmedHeading,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (at != null)
        Text(
          context.when(at, 'EEEE d MMMM y, h:mm a'),
          textAlign: TextAlign.center,
        ),
    ];
  }
}
