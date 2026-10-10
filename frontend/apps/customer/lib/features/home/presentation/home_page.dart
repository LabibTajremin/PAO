import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/home/data/api_home_repository.dart';
import 'package:pao_customer/features/home/domain/home_repository.dart';
import 'package:pao_customer/features/home/presentation/address_sheet.dart';
import 'package:pao_customer/features/home/presentation/category_grid.dart';
import 'package:pao_customer/features/home/presentation/home_cubit.dart';
import 'package:pao_customer/features/home/presentation/home_parts.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Home (C07, C35): address, search, active booking and categories.
class HomePage extends StatelessWidget {
  /// Creates the page.
  const HomePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HomeCubit(ApiHomeRepository(services.api)).loading(),
    child: Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, ViewState<HomeData>>(
          builder: (context, state) => ViewStateView<HomeData>(
            state: state,
            onRetry: context.read<HomeCubit>().load,
            builder: (context, data) => RefreshIndicator(
              onRefresh: context.read<HomeCubit>().refresh,
              child: _HomeBody(data: data),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    await context.push<bool>(Routes.addressNew);
    await cubit.refresh();
  }

  Future<void> _choose(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final choice = await showAddressSheet(
      context,
      addresses: data.addresses,
      currentId: data.current?.id,
    );
    if (!context.mounted) return;
    switch (choice) {
      case AddAddress():
        await _add(context);
      case UseAddress(:final id) when id != data.current?.id:
        final failure = await cubit.switchTo(id);
        if (failure == null || !context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.failureText(failure)!)));
      case _:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = data.active;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        AddressHeader(address: data.current, onTap: () => _choose(context)),
        const SizedBox(height: PaoSpace.lg),
        SearchBarButton(onTap: () => context.push(Routes.search)),
        if (active != null) ...[
          const SizedBox(height: PaoSpace.lg),
          ActiveBookingBanner(
            booking: active,
            onTap: () => context.push(
              Routes.booking(active.id, activePart(active.status)),
            ),
          ),
        ],
        const SizedBox(height: PaoSpace.lg),
        ..._content(context),
      ],
    );
  }

  List<Widget> _content(BuildContext context) {
    if (data.current == null) {
      return [
        PaoEmptyState(
          icon: Icons.add_location_alt_outlined,
          title: context.t.homeNoAddress,
          message: context.t.homeNoAddressBody,
          action: PaoButton(
            label: context.t.homeAddAddress,
            onPressed: () => _add(context),
            expand: false,
          ),
        ),
      ];
    }
    if (data.coverage?.covered == false) {
      return [AreaNotCovered(onChange: () => _choose(context))];
    }
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              context.t.homeCategories,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => context.push(Routes.services),
            child: Text(context.t.homeAllServices),
          ),
        ],
      ),
      if (data.categories.isEmpty)
        PaoEmptyState(title: context.t.homeNoServices)
      else
        CategoryGrid(categories: data.categories),
    ];
  }
}
