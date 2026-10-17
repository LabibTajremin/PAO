import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/presentation/bill.dart';
import 'package:pao_customer/features/live/data/api_live_repository.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The job is done: final bill and the cash payment (C16), then rating.
class CompletedPage extends StatelessWidget {
  /// Creates the page.
  const CompletedPage({
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
      () => ApiLiveRepository(services.api).booking(bookingId),
    ).loading(),
    child: BlocBuilder<LoadCubit<Booking>, ViewState<Booking>>(
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.liveCompletedTitle),
        body: ViewStateView<Booking>(
          state: s,
          onRetry: context.read<LoadCubit<Booking>>().load,
          builder: (_, b) => _Body(booking: b),
        ),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final name = b.provider?.name ?? '';
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        const Icon(Icons.task_alt, size: 64, color: PaoColors.success),
        const SizedBox(height: PaoSpace.md),
        Text(
          context.t.liveCompletedHeading,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: PaoSpace.lg),
        _payment(context, name),
        const SizedBox(height: PaoSpace.md),
        BillView(
          title: context.local(b.serviceName),
          lines: [for (final item in b.items) BillLine.of(item)],
          total: b.total,
        ),
        const SizedBox(height: PaoSpace.xl),
        ..._actions(context, name),
      ],
    );
  }

  // Cash is the only payment (D4); the provider confirms receiving it.
  Widget _payment(BuildContext context, String name) {
    final t = context.t;
    final amount = formatMoney(booking.total, locale: context.lang);
    final paid = booking.cashReceived ?? false;
    return PaoCard(
      highlighted: true,
      child: PaoListRow(
        leading: Icon(paid ? Icons.verified : Icons.payments_outlined),
        title: paid ? t.liveCompletedPaid(amount) : t.liveCompletedPay(amount),
        subtitle: paid ? null : t.liveCompletedPayBody(name),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, String name) {
    final t = context.t;
    final b = booking;
    return [
      if (b.reviewedByMe != true)
        PaoButton(
          label: t.liveCompletedRate(name),
          icon: Icons.star_outline,
          onPressed: () => context.go(Routes.booking(b.id, 'rate')),
        ),
      PaoButton(
        label: t.liveCompletedReceipt,
        variant: PaoButtonVariant.outline,
        onPressed: () => context.push(Routes.booking(b.id, 'receipt')),
      ),
      PaoButton(
        label: t.bookingBackHome,
        variant: PaoButtonVariant.ghost,
        onPressed: () => context.go(Routes.home),
      ),
    ];
  }
}
