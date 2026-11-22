import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';
import 'package:pao_partner/features/jobs/presentation/item_rows.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Shows the receipt of the completed job [bookingId] in a sheet, with the
/// admin's [tagline] at the foot.
Future<void> showReceipt(
  BuildContext context,
  JobsRepository repo,
  String bookingId, {
  required String tagline,
}) => showPaoSheet<void>(
  context,
  title: context.t.jobsReceiptTitle,
  child: BlocProvider(
    create: (_) => LoadCubit<Receipt>(() => repo.receipt(bookingId)).loading(),
    child: BlocBuilder<LoadCubit<Receipt>, ViewState<Receipt>>(
      builder: (context, state) => ViewStateView<Receipt>(
        state: state,
        onRetry: context.read<LoadCubit<Receipt>>().load,
        builder: (_, receipt) =>
            _ReceiptBody(receipt: receipt, tagline: tagline),
      ),
    ),
  ),
);

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt, required this.tagline});

  final Receipt receipt;
  final String tagline;

  @override
  Widget build(BuildContext context) => Flexible(
    child: SingleChildScrollView(
      child: Stack(
        children: [
          const Positioned.fill(child: Center(child: PaoWatermark())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PaoLogo(height: 36),
              const SizedBox(height: PaoSpace.sm),
              Text(
                '${receipt.number} · ${context.local(receipt.serviceName)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(context.when(receipt.completedAt)),
              Text(context.t.jobsCustomer(receipt.customerName)),
              ItemRows(items: receipt.items, total: receipt.total),
              Text(context.t.jobsPaidCash),
              const SizedBox(height: PaoSpace.lg),
              Center(
                child: Text(
                  tagline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
