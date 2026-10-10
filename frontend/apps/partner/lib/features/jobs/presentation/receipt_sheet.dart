import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';
import 'package:pao_partner/features/jobs/presentation/formats.dart';
import 'package:pao_partner/features/jobs/presentation/item_rows.dart';
import 'package:pao_partner/features/jobs/presentation/load_on_create.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Shows the receipt of the completed job [bookingId] in a sheet.
Future<void> showReceipt(
  BuildContext context,
  JobsRepository repo,
  String bookingId,
) => showPaoSheet<void>(
  context,
  title: context.t.jobsReceiptTitle,
  child: BlocProvider(
    create: (_) => LoadCubit<Receipt>(() => repo.receipt(bookingId)).loading(),
    child: BlocBuilder<LoadCubit<Receipt>, ViewState<Receipt>>(
      builder: (context, state) => ViewStateView<Receipt>(
        state: state,
        onRetry: context.read<LoadCubit<Receipt>>().load,
        builder: (_, receipt) => _ReceiptBody(receipt: receipt),
      ),
    ),
  ),
);

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) => Flexible(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${receipt.number} · ${context.local(receipt.serviceName)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(context.when(receipt.completedAt)),
          Text(context.t.jobsCustomer(receipt.customerName)),
          ItemRows(items: receipt.items, total: receipt.total),
          Text(context.t.jobsPaidCash),
        ],
      ),
    ),
  );
}
