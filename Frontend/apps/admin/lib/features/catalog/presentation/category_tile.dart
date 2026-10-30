import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_icons.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// One category of the tree with its services and their sub-services.
class CategoryTile extends StatelessWidget {
  /// Creates the tile.
  const CategoryTile({required this.category, required this.onEdit, super.key});

  /// The category.
  final Category category;

  /// Opens the category form.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final other = context.lang == 'bn' ? category.name.en : category.name.bn;
    return PaoCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        leading: PaoIconTile(icon: catalogIcon(category.iconKey), size: 40),
        title: Text(context.local(category.name)),
        subtitle: Text(
          t.catalogCategoryLine(
            other,
            context.count(category.sortOrder),
            context.count(category.services.length),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PublishedBadge(published: category.published),
            IconButton(
              tooltip: t.catalogEditCategory,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
        children: [
          for (final s in category.services) _ServiceRow(service: s),
          _AddService(categoryId: category.id),
        ],
      ),
    );
  }
}

class _AddService extends StatelessWidget {
  const _AddService({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.all(PaoSpace.sm),
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: Text(context.t.catalogNewService),
        onPressed: () =>
            context.go('${Routes.serviceOf('new')}?category=$categoryId'),
      ),
    ),
  );
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final subs = service.subServices ?? const <SubService>[];
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: Icon(catalogIcon(service.iconKey)),
          title: Text(context.local(service.name)),
          subtitle: Text(
            '${modelLabel(t, service.serviceModel)} · '
            '${levelName(t, service.requiredLevel)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PublishedBadge(published: service.published),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => context.go(Routes.serviceOf(service.id)),
        ),
        for (final sub in subs) _SubServiceLine(sub: sub),
      ],
    );
  }
}

class _SubServiceLine extends StatelessWidget {
  const _SubServiceLine({required this.sub});

  final SubService sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(72, 0, PaoSpace.lg, PaoSpace.sm),
    child: Row(
      spacing: PaoSpace.md,
      children: [
        Expanded(child: Text(context.local(sub.name))),
        Text(
          '${context.money(sub.price)} ${unitLabel(context.t, sub.unit)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (!sub.published) PublishedBadge(published: sub.published),
      ],
    ),
  );
}
