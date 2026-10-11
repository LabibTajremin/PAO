import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/features/catalog/presentation/price_panel.dart';
import 'package:pao_admin/features/catalog/presentation/sub_service_dialog.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/detail_drawer.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The sub-services of a service with their prices; each can be edited or
/// given a new price.
class SubServiceList extends StatelessWidget {
  /// Creates the list.
  const SubServiceList({required this.service, required this.cubit, super.key});

  /// The service.
  final Service service;

  /// Saves sub-services and reloads after a price change.
  final ServiceEditorCubit cubit;

  Future<void> _edit(BuildContext context, [SubService? sub]) async {
    final saved = await showSubServiceDialog(
      context,
      cubit: cubit,
      serviceId: service.id,
      sub: sub,
    );
    if ((saved ?? false) && context.mounted) {
      showDone(context, context.t.formSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final subs = service.subServices ?? const <SubService>[];
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.catalogSubServices,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PaoButton(
                label: t.catalogNewSubService,
                icon: Icons.add,
                variant: PaoButtonVariant.soft,
                expand: false,
                onPressed: () => _edit(context),
              ),
            ],
          ),
          const SizedBox(height: PaoSpace.md),
          if (subs.isEmpty) Text(t.catalogNoSubServices),
          for (final sub in subs)
            _SubRow(
              sub: sub,
              onEdit: () => _edit(context, sub),
              onPrice: () => _prices(context, sub),
            ),
        ],
      ),
    );
  }

  Future<void> _prices(BuildContext context, SubService sub) =>
      showDetailDrawer<void>(
        context,
        title: context.t.catalogPricesOf(context.local(sub.name)),
        child: PricePanel(
          repository: cubit.repository,
          sub: sub,
          onChanged: cubit.refresh,
        ),
      );
}

class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.sub,
    required this.onEdit,
    required this.onPrice,
  });

  final SubService sub;
  final VoidCallback onEdit;
  final VoidCallback onPrice;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final limit = sub.maxQuantity;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.local(sub.name)),
      subtitle: Text(
        [
          '${context.money(sub.price)} ${unitLabel(t, sub.unit)}',
          if (limit != null) t.catalogMaxLine(context.count(limit)),
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PublishedBadge(published: sub.published),
          IconButton(
            tooltip: t.catalogPrices,
            icon: const Icon(Icons.sell_outlined),
            onPressed: onPrice,
          ),
          IconButton(
            tooltip: t.catalogEditSub,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
