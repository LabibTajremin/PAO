import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/verification/domain/verification_repository.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/features/verification/presentation/page_header.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Providers waiting for document review, oldest first (A05).
class QueuePage extends StatefulWidget {
  /// Creates the page over [repo].
  const QueuePage({required this.repo, super.key});

  /// Where the queue comes from.
  final VerificationRepository repo;

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  ItemType? _item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeader(title: context.t.verifyQueueTitle),
      Expanded(
        child: BlocProvider(
          key: ValueKey(_item),
          create: (_) => PagedCubit<VerificationQueueItem>(
            (cursor) => widget.repo.queue(itemType: _item, cursor: cursor),
          ).loading(),
          child: PagedTable<VerificationQueueItem>(
            header: [
              FilterBar(filters: [_itemFilter(context)]),
            ],
            columns: _columns(context),
            empty: PaoEmptyState(
              icon: Icons.task_alt,
              title: context.t.verifyQueueEmpty,
            ),
            onOpen: (row) => context.go(Routes.reviewOf(row.providerId)),
          ),
        ),
      ),
    ],
  );

  Widget _itemFilter(BuildContext context) => DropdownMenu<ItemType?>(
    width: 240,
    label: Text(context.t.verifyFilterItem),
    initialSelection: _item,
    onSelected: (value) => setState(() => _item = value),
    dropdownMenuEntries: [
      DropdownMenuEntry(value: null, label: context.t.verifyFilterAll),
      for (final type in ItemType.values)
        DropdownMenuEntry(value: type, label: itemLabel(context.t, type)),
    ],
  );

  List<AdminColumn<VerificationQueueItem>> _columns(BuildContext context) {
    final t = context.t;
    return [
      AdminColumn(t.verifyColProvider, (r) => Text(r.name), flex: 2),
      AdminColumn(
        t.verifyColServices,
        (r) => Text(
          (r.services ?? []).map((s) => context.local(s.name)).join(', '),
        ),
        flex: 2,
      ),
      AdminColumn(
        t.verifyColPending,
        (r) => _PendingItems(r.pendingItems),
        flex: 3,
      ),
      AdminColumn(
        t.verifyColWaiting,
        (r) => Text(
          waitedLabel(t, r.ageHours),
          style: TextStyle(
            color: waitedColor(r.ageHours),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }
}

class _PendingItems extends StatelessWidget {
  const _PendingItems(this.items);

  final List<ItemType> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.xs,
    runSpacing: PaoSpace.xs,
    children: [for (final i in items) PaoBadge(label: itemLabel(context.t, i))],
  );
}
