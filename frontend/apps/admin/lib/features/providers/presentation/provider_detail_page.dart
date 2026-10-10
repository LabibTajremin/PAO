import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/providers/data/api_providers_repository.dart';
import 'package:pao_admin/features/providers/domain/providers_repository.dart';
import 'package:pao_admin/features/providers/presentation/provider_sections.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/ops/record_cubit.dart';
import 'package:pao_admin/shared/ops/records.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

typedef _Cubit = RecordCubit<AdminProviderDetail>;

/// One provider: profile, verification, bookings and status history, with
/// suspend, ban and reinstate for admins holding `provider:manage` (A08).
class ProviderDetailPage extends StatelessWidget {
  /// Creates the page for provider [id].
  const ProviderDetailPage({
    required this.services,
    required this.id,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The provider's ID.
  final String id;

  Future<void> _change(
    BuildContext context,
    ProvidersRepository repo,
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
    final repo = ApiProvidersRepository(services.api);
    final permissions = services.permissions;
    return BlocProvider(
      create: (_) => _Cubit(() => repo.detail(id)).loading(),
      child: BlocBuilder<_Cubit, ViewState<AdminProviderDetail>>(
        builder: (context, state) => DetailFrame<AdminProviderDetail>(
          back: BackLink(label: context.t.providersAll, to: Routes.providers),
          state: state,
          onRetry: context.read<_Cubit>().load,
          builder: (context, d) => SplitColumns(
            first: [
              ProviderProfileCard(
                detail: d,
                onChange: permissions.can('provider:manage')
                    ? (change) => _change(context, repo, change)
                    : null,
              ),
              VerificationSummary(items: d.items),
            ],
            second: [
              Section(
                title: context.t.peopleRecentBookings,
                child: BookingSummaryList(
                  bookings: d.recentBookings,
                  canOpen: permissions.canSee('A10'),
                ),
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
