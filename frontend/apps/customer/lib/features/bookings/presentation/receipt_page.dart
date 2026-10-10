import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/bookings/data/api_bookings_repository.dart';
import 'package:pao_customer/features/bookings/data/receipt_pdf.dart';
import 'package:pao_customer/features/bookings/data/share_pdf.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';
import 'package:pao_customer/features/bookings/presentation/bill_rows.dart';
import 'package:pao_customer/features/bookings/presentation/receipt_share_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The receipt of a completed booking, shareable as a PDF (C64).
class ReceiptPage extends StatelessWidget {
  /// Creates the page for [bookingId]; [share] defaults to the share sheet.
  const ReceiptPage({
    required this.services,
    required this.bookingId,
    this.share = sharePdf,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The booking.
  final String bookingId;

  /// Hands the PDF to other apps.
  final ShareFile share;

  @override
  Widget build(BuildContext context) {
    final repo = ApiBookingsRepository(services.api);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              LoadCubit<Receipt>(() => repo.receipt(bookingId)).loading(),
        ),
        BlocProvider(
          create: (_) => ReceiptShareCubit(
            render: receiptPdf,
            share: share,
            fileName: receiptFileName,
          ),
        ),
      ],
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.bookingsReceiptTitle),
        body: BlocBuilder<LoadCubit<Receipt>, ViewState<Receipt>>(
          builder: (context, state) => ViewStateView<Receipt>(
            state: state,
            onRetry: context.read<LoadCubit<Receipt>>().load,
            builder: (_, receipt) => _ReceiptView(receipt: receipt),
          ),
        ),
      ),
    );
  }
}

class _ReceiptView extends StatelessWidget {
  const _ReceiptView({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    final r = receipt;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        PaoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PAO', style: text.headlineSmall),
              Text(t.bookingsReceiptNumber(r.number), style: text.bodySmall),
              Text(t.bookingsReceiptCompleted(context.when(r.completedAt))),
              const Divider(),
              _Fact(t.bookingsReceiptService, context.local(r.serviceName)),
              _Fact(t.bookingsReceiptProvider, r.providerName),
              _Fact(t.bookingsReceiptCustomer, r.customerName),
              if (r.area case final String area)
                _Fact(t.bookingsReceiptArea, area),
              const Divider(),
              BillRows(items: r.items, total: r.total),
              Text(t.bookingsPaidCash, style: text.bodySmall),
              const SizedBox(height: PaoSpace.md),
              Text(t.bookingsReceiptThanks),
            ],
          ),
        ),
        const SizedBox(height: PaoSpace.xl),
        _ShareButton(receipt: r),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: PaoSpace.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(value),
      ],
    ),
  );
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ReceiptShareCubit, ReceiptShareState>(
        listenWhen: (_, s) => s.failed,
        listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.bookingsReceiptShareFailed)),
        ),
        builder: (context, s) => PaoButton(
          label: context.t.bookingsReceiptShare,
          icon: Icons.ios_share,
          loading: s.busy,
          onPressed: () =>
              context.read<ReceiptShareCubit>().shareReceipt(receipt),
        ),
      );
}
