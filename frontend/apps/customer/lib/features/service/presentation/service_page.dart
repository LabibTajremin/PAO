import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/service/data/api_service_repository.dart';
import 'package:pao_customer/features/service/domain/selection.dart';
import 'package:pao_customer/features/service/presentation/hire_section.dart';
import 'package:pao_customer/features/service/presentation/selection_cubit.dart';
import 'package:pao_customer/features/service/presentation/service_footer.dart';
import 'package:pao_customer/features/service/presentation/sub_service_tile.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Service detail (C09), home salon (C43) and driver hire (C44).
class ServicePage extends StatelessWidget {
  /// Creates the page; [preselect] is a sub-service chosen in search.
  const ServicePage({
    required this.services,
    required this.serviceId,
    this.preselect,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The service shown.
  final String serviceId;

  /// A sub-service to start with a quantity of one.
  final String? preselect;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<Service>(
      () => ApiServiceRepository(services.api).service(serviceId),
    ).loading(),
    child: BlocBuilder<LoadCubit<Service>, ViewState<Service>>(
      // The loaded page brings its own scaffold with the service name and
      // the total; this one only frames loading and failure.
      builder: (context, state) => Scaffold(
        appBar: state is ViewData ? null : const PaoAppBar(title: ''),
        body: ViewStateView<Service>(
          state: state,
          onRetry: context.read<LoadCubit<Service>>().load,
          builder: (_, data) => _Loaded(
            service: data,
            initial: _initial(data),
            now: services.now,
          ),
        ),
      ),
    ),
  );

  Map<String, int> _initial(Service service) {
    final subs = bookable(service);
    for (final s in subs) {
      if (s.id == preselect) return {s.id: 1};
    }
    final hire = service.serviceModel == ServiceModel.durationHire;
    return hire && subs.isNotEmpty ? {subs.first.id: 1} : const {};
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.service,
    required this.initial,
    required this.now,
  });

  final Service service;
  final Map<String, int> initial;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SelectionCubit(initial),
    child: BlocBuilder<SelectionCubit, Selection>(
      builder: (context, selection) => Scaffold(
        appBar: PaoAppBar(title: context.local(service.name)),
        body: _body(context, selection),
        bottomNavigationBar: bookable(service).isEmpty
            ? null
            : ServiceFooter(service: service, selection: selection, now: now()),
      ),
    ),
  );

  Widget _body(BuildContext context, Selection selection) {
    final subs = bookable(service);
    if (subs.isEmpty) return PaoEmptyState(title: context.t.svcNoItems);
    final cubit = context.read<SelectionCubit>();
    final hire = service.serviceModel == ServiceModel.durationHire;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        if (service.womenProvidersOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: PaoSpace.md),
            child: PaoCard(
              highlighted: true,
              child: Row(
                children: [
                  const Icon(Icons.female),
                  const SizedBox(width: PaoSpace.sm),
                  Expanded(child: Text(context.t.svcWomenOnly)),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: PaoSpace.md),
          child: Text(
            context.t.svcFixedPrice,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (hire)
          HireSection(service: service, selection: selection, now: now())
        else
          for (final s in subs)
            SubServiceTile(
              sub: s,
              quantity: selection.items[s.id] ?? 0,
              onChanged: (q) => cubit.quantity(s.id, q),
            ),
      ],
    );
  }
}
