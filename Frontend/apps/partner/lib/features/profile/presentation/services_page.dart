import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/data/api_service_area_repository.dart';
import 'package:pao_partner/features/profile/domain/service_area_repository.dart';
import 'package:pao_partner/features/profile/presentation/services_cubit.dart';
import 'package:pao_partner/features/profile/presentation/services_form.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Services offered and the service area (M33).
class ServicesPage extends StatelessWidget {
  /// Creates the page.
  const ServicesPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ServicesCubit(ApiServiceAreaRepository(services.api)).loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.profServicesTitle),
      body: BlocBuilder<ServicesCubit, ViewState<ServiceArea>>(
        builder: (context, state) => ViewStateView<ServiceArea>(
          state: state,
          onRetry: context.read<ServicesCubit>().load,
          builder: (_, area) =>
              ServicesForm(area: area, location: services.location),
        ),
      ),
    ),
  );
}
