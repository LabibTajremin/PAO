import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/search/data/api_search_repository.dart';
import 'package:pao_customer/features/search/presentation/search_cubit.dart';
import 'package:pao_customer/shared/catalog_icons.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_customer/shared/price_units.dart';
import 'package:pao_ui/pao_ui.dart';

/// Search services and sub-services (C08, C38).
class SearchPage extends StatelessWidget {
  /// Creates the page.
  const SearchPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SearchCubit(ApiSearchRepository(services.api)),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.t.searchHint,
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: context.read<SearchCubit>().query,
          ),
        ),
        body: BlocBuilder<SearchCubit, SearchState>(builder: _body),
      ),
    ),
  );

  Widget _body(BuildContext context, SearchState s) {
    final common = context.common;
    final results = s.results;
    if (s.query.isEmpty) {
      return PaoMessageState(icon: Icons.search, title: context.t.searchPrompt);
    }
    if (s.failure case final failure?) {
      return PaoErrorState(
        title: common.errorTitle,
        message: context.failureText(failure)!,
        onRetry: context.read<SearchCubit>().retry,
        retryLabel: common.actionRetry,
      );
    }
    if (results == null) {
      return Padding(
        padding: const EdgeInsets.all(PaoSpace.lg),
        child: PaoSkeletonList(semanticLabel: common.loading),
      );
    }
    if (s.nothingFound) return _NoResults(query: s.query);
    return _Results(results: results);
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => PaoEmptyState(
    icon: Icons.search_off,
    title: context.t.searchNoResults(query),
    message: context.t.searchNoResultsBody,
    action: PaoButton(
      label: context.t.homeAllServices,
      variant: PaoButtonVariant.soft,
      expand: false,
      onPressed: () => context.push(Routes.services),
    ),
  );
}

class _Results extends StatelessWidget {
  const _Results({required this.results});

  final CatalogSearchResults results;

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.titleSmall;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        if (results.services.isNotEmpty)
          Text(context.t.searchServices, style: heading),
        for (final s in results.services)
          PaoListRow(
            leading: PaoIconTile(icon: catalogIcon(s.iconKey), size: 40),
            title: context.local(s.name),
            onTap: () => context.push(Routes.serviceOf(s.id)),
          ),
        if (results.subServices.isNotEmpty) ...[
          const SizedBox(height: PaoSpace.lg),
          Text(context.t.searchSubServices, style: heading),
        ],
        for (final sub in results.subServices)
          PaoListRow(
            title: context.local(sub.name),
            subtitle: priceWithUnit(context, sub),
            onTap: () => context.push(
              Uri(
                path: Routes.serviceOf(sub.serviceId),
                queryParameters: {'sub': sub.id},
              ).toString(),
            ),
          ),
      ],
    );
  }
}
