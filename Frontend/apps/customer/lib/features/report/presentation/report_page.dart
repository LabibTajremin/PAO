import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/report/data/api_report_repository.dart';
import 'package:pao_customer/features/report/presentation/report_cubit.dart';
import 'package:pao_customer/features/report/presentation/report_form.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Report a problem on a booking (C20), then the ticket number (C56).
class ReportPage extends StatelessWidget {
  /// Creates the page for [bookingId].
  const ReportPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The booking.
  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReportCubit(ApiReportRepository(services.api), bookingId),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.reportTitle),
      body: BlocBuilder<ReportCubit, ReportState>(
        buildWhen: (a, b) => a.ticket != b.ticket,
        builder: (context, s) => s.ticket == null
            ? ReportForm(photos: services.photos)
            : PaoMessageState(
                icon: Icons.check_circle_outline,
                title: context.t.reportSent,
                message: context.t.reportTicket(s.ticket!),
                action: PaoButton(
                  label: context.t.reportBackToBooking,
                  expand: false,
                  onPressed: () => context.go(Routes.booking(bookingId)),
                ),
              ),
      ),
    ),
  );
}
