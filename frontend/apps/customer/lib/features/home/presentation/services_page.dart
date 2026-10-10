import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/home/data/api_home_repository.dart';
import 'package:pao_customer/shared/catalog_icons.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// All services by category (C37); [categoryId] narrows it to one category.
class ServicesPage extends StatelessWidget {
  /// Creates the page.
  const ServicesPage({required this.services, this.categoryId, super.key});

  /// App services.
  final AppServices services;

  /// The category to show, or null for all.
  final String? categoryId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        LoadCubit<List<Category>>(ApiCatalogRepository(services.api).categories)
            .loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.homeAllServices),
      body: BlocBuilder<LoadCubit<List<Category>>, ViewState<List<Category>>>(
        builder: (context, state) => ViewStateView<List<Category>>(
          state: state,
          onRetry: context.read<LoadCubit<List<Category>>>().load,
          isEmpty: (all) => _shown(all).isEmpty,
          empty: PaoEmptyState(title: context.t.homeNoServices),
          builder: (_, all) => _List(categories: _shown(all)),
        ),
      ),
    ),
  );

  List<Category> _shown(List<Category> all) => [
    for (final c in all)
      if (categoryId == null || c.id == categoryId) c,
  ];
}

class _List extends StatelessWidget {
  const _List({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(PaoSpace.lg),
    children: [
      for (final c in categories) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: PaoSpace.sm),
          child: Text(
            context.local(c.name),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final s in c.services)
          PaoListRow(
            leading: PaoIconTile(icon: catalogIcon(s.iconKey), size: 40),
            title: context.local(s.name),
            onTap: () => context.push(Routes.serviceOf(s.id)),
          ),
      ],
    ],
  );
}
