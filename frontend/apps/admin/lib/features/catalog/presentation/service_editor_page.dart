import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/catalog/data/api_catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/service_form.dart';
import 'package:pao_admin/features/catalog/presentation/sub_service_list.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Path segment that opens the editor on a new service.
const newServiceId = 'new';

/// The service editor with its sub-services and prices (A04, PRD A-02).
class ServiceEditorPage extends StatelessWidget {
  /// Creates the editor for [id], or a new service under [categoryId] when
  /// [id] is [newServiceId].
  const ServiceEditorPage({
    required this.services,
    required this.id,
    this.categoryId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Service ID from the path.
  final String id;

  /// Category a new service starts in.
  final String? categoryId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    // A new service, once saved, reopens under its ID with fresh data.
    key: ValueKey(id),
    create: (_) => ServiceEditorCubit(
      ApiCatalogRepository(services.api),
      id == newServiceId ? null : id,
    ).loading(),
    child: BlocBuilder<ServiceEditorCubit, ViewState<ServiceEditorData>>(
      builder: (context, state) => ConsolePage(
        leading: IconButton(
          tooltip: context.t.catalogBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.catalog),
        ),
        title: switch (state) {
          ViewData(data: ServiceEditorData(:final service?)) => context.local(
            service.name,
          ),
          _ when id == newServiceId => context.t.catalogNewService,
          _ => context.t.catalogServiceTitle,
        },
        child: ViewStateView<ServiceEditorData>(
          state: state,
          onRetry: context.read<ServiceEditorCubit>().load,
          builder: _body,
        ),
      ),
    ),
  );

  Widget _body(BuildContext context, ServiceEditorData data) {
    final cubit = context.read<ServiceEditorCubit>();
    final service = data.service;
    final known = data.categories.any((c) => c.id == categoryId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PaoSpace.xxl,
        PaoSpace.sm,
        PaoSpace.xxl,
        PaoSpace.xxl,
      ),
      children: [
        ServiceForm(
          data: data,
          cubit: cubit,
          categoryId: known ? categoryId : null,
        ),
        if (service != null) ...[
          const SizedBox(height: PaoSpace.xxl),
          SubServiceList(service: service, cubit: cubit),
        ],
      ],
    );
  }
}
