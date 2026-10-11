import 'package:flutter/material.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// What the verifier may do on an item card; null callbacks hide the action.
class ItemActions {
  /// Creates the actions.
  const ItemActions({
    this.decide = false,
    this.onFocus,
    this.onApprove,
    this.onReject,
    this.onDocuments,
  });

  /// Shows approve and reject; they are disabled while their callbacks are
  /// null (a decision is in flight).
  final bool decide;

  /// Makes the item the one the shortcuts act on.
  final VoidCallback? onFocus;

  /// Approves the item.
  final VoidCallback? onApprove;

  /// Rejects the item.
  final VoidCallback? onReject;

  /// Opens the item's documents.
  final VoidCallback? onDocuments;
}

/// One verification item with its submitted values, documents and the
/// approve / reject actions while it is pending.
class ItemCard extends StatelessWidget {
  /// Creates the card.
  const ItemCard({
    required this.item,
    required this.actions,
    this.focused = false,
    this.docsLocked = false,
    super.key,
  });

  /// The item.
  final ReviewItem item;

  /// Available actions.
  final ItemActions actions;

  /// The shortcuts act on this item.
  final bool focused;

  /// The item has documents the admin may not open.
  final bool docsLocked;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final docs = item.documents ?? const [];
    return PaoCard(
      highlighted: focused,
      onTap: actions.onFocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.sm,
        children: [
          _Title(item: item),
          if (item.rejectionReason case final reason?)
            Text(
              t.verifyRejectedBecause(reason),
              style: const TextStyle(color: PaoColors.danger),
            ),
          if (item.expiresAt case final at?)
            Text(t.verifyExpires(context.when(at, 'd MMM y'))),
          if (item.decidedAt case final at?)
            Text(t.verifyDecidedAt(context.when(at))),
          ..._fields(context),
          if (docs.isNotEmpty)
            _Documents(item: item, actions: actions, locked: docsLocked),
          if (actions.decide) _Decide(actions: actions),
        ],
      ),
    );
  }

  Iterable<Widget> _fields(BuildContext context) => (item.fields ?? const {})
      .entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => Text('${fieldLabel(context.t, e.key)}: ${e.value}'));
}

class _Title extends StatelessWidget {
  const _Title({required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Wrap(
      spacing: PaoSpace.sm,
      runSpacing: PaoSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          itemLabel(t, item.type),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        PaoBadge(
          label: statusLabel(t, item.status),
          tone: statusTone(item.status),
        ),
        Text(
          item.required_ ? t.verifyRequired : t.verifyOptional,
          style: const TextStyle(color: PaoColors.textSecondary),
        ),
      ],
    );
  }
}

class _Documents extends StatelessWidget {
  const _Documents({
    required this.item,
    required this.actions,
    required this.locked,
  });

  final ReviewItem item;
  final ItemActions actions;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final names = item.documents!.map((d) => documentLabel(t, d.kind));
    return Wrap(
      spacing: PaoSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(names.join(' · ')),
        if (locked)
          PaoBadge(label: t.verifyDocsLocked, icon: Icons.lock_outline)
        else
          TextButton.icon(
            icon: const Icon(Icons.image_search),
            label: Text(t.verifyOpenDocs),
            onPressed: actions.onDocuments,
          ),
      ],
    );
  }
}

class _Decide extends StatelessWidget {
  const _Decide({required this.actions});

  final ItemActions actions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.sm,
    children: [
      PaoButton(
        label: context.t.verifyApprove,
        icon: Icons.check,
        expand: false,
        onPressed: actions.onApprove,
      ),
      PaoButton(
        label: context.t.verifyReject,
        icon: Icons.close,
        variant: PaoButtonVariant.outline,
        expand: false,
        onPressed: actions.onReject,
      ),
    ],
  );
}
