import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/dashboard/data/api_dashboard_repository.dart';
import 'package:pao_admin/features/dashboard/presentation/dashboard_body.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Key counts and charts for the operations team (A02, PRD A-09).
class DashboardPage extends StatelessWidget {
  /// Creates the page.
  const DashboardPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        LoadCubit<Dashboard>(ApiDashboardRepository(services.api).load)
            .loading(),
    child: BlocBuilder<LoadCubit<Dashboard>, ViewState<Dashboard>>(
      builder: (context, state) {
        final cubit = context.read<LoadCubit<Dashboard>>();
        return ConsolePage(
          title: context.t.dashTitle,
          subtitle: switch (state) {
            ViewData(:final data) => context.t.dashUpdated(
              context.when(data.generatedAt),
            ),
            _ => null,
          },
          actions: [
            IconButton(
              tooltip: context.t.dashRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: state is ViewLoading ? null : cubit.load,
            ),
          ],
          child: ViewStateView<Dashboard>(
            state: state,
            onRetry: cubit.load,
            builder: (_, data) =>
                DashboardBody(data: data, permissions: services.permissions),
          ),
        );
      },
    ),
  );
}
