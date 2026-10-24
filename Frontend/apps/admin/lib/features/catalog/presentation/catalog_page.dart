import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/catalog/data/api_catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/category_dialog.dart';
import 'package:pao_admin/features/catalog/presentation/category_tile.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// The catalog tree: categories, their services and sub-services, published
/// or hidden (A03, PRD A-02).
class CatalogPage extends StatelessWidget {
  /// Creates the page.
  const CatalogPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CatalogCubit(ApiCatalogRepository(services.api)).loading(),
    child: BlocBuilder<CatalogCubit, ViewState<CatalogTree>>(
      builder: (context, state) {
        final cubit = context.read<CatalogCubit>();
        return ConsolePage(
          title: context.t.catalogTitle,
          subtitle: switch (state) {
            ViewData(:final data) => context.t.catalogVersion(
              context.count(data.version),
            ),
            _ => null,
          },
          actions: [
            PaoButton(
              label: context.t.catalogNewCategory,
              icon: Icons.add,
              expand: false,
              onPressed: () => _edit(context, cubit, null),
            ),
          ],
          child: ViewStateView<CatalogTree>(
            state: state,
            onRetry: cubit.load,
            isEmpty: (tree) => tree.categories.isEmpty,
            empty: PaoEmptyState(
              title: context.t.catalogEmptyTitle,
              message: context.t.catalogEmptyBody,
            ),
            builder: (context, tree) => _tree(context, cubit, tree),
          ),
        );
      },
    ),
  );

  Widget _tree(BuildContext context, CatalogCubit cubit, CatalogTree tree) {
    final categories = [...tree.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        PaoSpace.xxl,
        PaoSpace.sm,
        PaoSpace.xxl,
        PaoSpace.xxl,
      ),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: PaoSpace.md),
      itemBuilder: (context, i) => CategoryTile(
        category: categories[i],
        onEdit: () => _edit(context, cubit, categories[i]),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    CatalogCubit cubit,
    Category? category,
  ) async {
    final saved = await showCategoryDialog(
      context,
      cubit: cubit,
      category: category,
    );
    if ((saved ?? false) && context.mounted) {
      showDone(context, context.t.formSaved);
    }
  }
}
