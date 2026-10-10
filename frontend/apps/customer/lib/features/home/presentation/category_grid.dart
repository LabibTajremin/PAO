import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/shared/catalog_icons.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_ui/pao_ui.dart';

/// Where a category leads: straight to its service when it has only one,
/// otherwise to the list of its services (C37).
String categoryTarget(Category c) => c.services.length == 1
    ? Routes.serviceOf(c.services.single.id)
    : Uri(
        path: Routes.services,
        queryParameters: {'category': c.id},
      ).toString();

/// The category grid on home (C07).
class CategoryGrid extends StatelessWidget {
  /// Creates the grid.
  const CategoryGrid({required this.categories, super.key});

  /// Published categories in order.
  final List<Category> categories;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: PaoSpace.md,
    crossAxisSpacing: PaoSpace.md,
    childAspectRatio: 0.95,
    children: [
      for (final c in categories)
        PaoCard(
          padding: const EdgeInsets.all(PaoSpace.sm),
          onTap: () => context.push(categoryTarget(c)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PaoIconTile(icon: catalogIcon(c.iconKey)),
              const SizedBox(height: PaoSpace.sm),
              Text(
                context.local(c.name),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
    ],
  );
}
