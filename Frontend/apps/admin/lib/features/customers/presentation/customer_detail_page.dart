import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/customers/data/api_customers_repository.dart';
import 'package:pao_admin/features/customers/domain/customers_repository.dart';
import 'package:pao_admin/features/customers/presentation/customer_sections.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/ops/record_cubit.dart';
import 'package:pao_admin/shared/ops/records.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

typedef _Cubit = RecordCubit<AdminCustomerDetail>;

/// One customer: profile, bookings, complaints and status history, with
/// suspend, ban and reinstate for admins holding `customer:manage` (A09).
class CustomerDetailPage extends StatelessWidget {
  /// Creates the page for customer [id].
  const CustomerDetailPage({
    required this.services,
    required this.id,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The customer's ID.
  final String id;

  Future<void> _change(
    BuildContext context,
    CustomersRepository repo,
    AccountStatusChange change,
  ) async {
    final failure = await context.read<_Cubit>().act(
      () => repo.changeStatus(id, change),
    );
    if (!context.mounted) return;
    showOutcome(context, failure, context.t.peopleStatusChanged);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ApiCustomersRepository(services.api);
    final permissions = services.permissions;
    return BlocProvider(
      create: (_) => _Cubit(() => repo.detail(id)).loading(),
      child: BlocBuilder<_Cubit, ViewState<AdminCustomerDetail>>(
        builder: (context, state) => DetailFrame<AdminCustomerDetail>(
          back: BackLink(label: context.t.customersAll, to: Routes.customers),
          state: state,
          onRetry: context.read<_Cubit>().load,
          builder: (context, d) => SplitColumns(
            first: [
              CustomerProfileCard(
                summary: d.summary,
                onChange: permissions.can('customer:manage')
                    ? (change) => _change(context, repo, change)
                    : null,
              ),
              Section(
                title: context.t.peopleRecentBookings,
                child: BookingSummaryList(
                  bookings: d.recentBookings,
                  canOpen: permissions.canSee('A10'),
                ),
              ),
            ],
            second: [
              CustomerComplaints(
                complaints: d.complaints,
                canOpen: permissions.canSee('A11'),
              ),
              Section(
                title: context.t.peopleHistory,
                child: StatusHistory(entries: d.statusHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
