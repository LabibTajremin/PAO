import 'package:flutter/material.dart';
import 'package:pao_admin/features/verification/presentation/item_card.dart';
import 'package:pao_admin/features/verification/presentation/profile_panel.dart';
import 'package:pao_admin/features/verification/presentation/review_cubit.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Width from which the profile sits beside the items.
const twoColumns = 900.0;

/// What the review body may do; null callbacks mean the admin lacks the
/// permission.
class ReviewHandlers {
  /// Creates the handlers.
  const ReviewHandlers({
    required this.onFocus,
    this.onApprove,
    this.onReject,
    this.onDocuments,
  });

  /// Focuses a pending item.
  final ValueChanged<ItemType> onFocus;

  /// Approves an item.
  final ValueChanged<ItemType>? onApprove;

  /// Rejects an item.
  final ValueChanged<ItemType>? onReject;

  /// Opens an item's documents.
  final ValueChanged<ReviewItem>? onDocuments;
}

/// The profile beside the items, pending ones first (A06).
class ReviewBody extends StatelessWidget {
  /// Creates the body.
  const ReviewBody({required this.state, required this.handlers, super.key});

  /// The loaded review state.
  final ReviewState state;

  /// Actions.
  final ReviewHandlers handlers;

  @override
  Widget build(BuildContext context) {
    final review = state.review!;
    final items = [
      ...review.items.where((i) => i.status == ItemStatus.pending),
      ...review.items.where((i) => i.status != ItemStatus.pending),
    ];
    final cards = [
      if (pendingOf(review).isEmpty)
        PaoMessageState(icon: Icons.task_alt, title: context.t.verifyNoPending),
      for (final item in items) _card(item),
    ];
    final profile = ProfilePanel(review: review);
    return LayoutBuilder(
      builder: (_, box) => box.maxWidth >= twoColumns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: _list([profile])),
                Expanded(child: _list(cards)),
              ],
            )
          : _list([profile, ...cards]),
    );
  }

  Widget _list(List<Widget> children) => ListView(
    padding: const EdgeInsets.all(PaoSpace.lg),
    children: [
      for (final c in children)
        Padding(
          padding: const EdgeInsets.only(bottom: PaoSpace.md),
          child: c,
        ),
    ],
  );

  Widget _card(ReviewItem item) {
    final pending = item.status == ItemStatus.pending;
    final h = handlers;
    final idle = !state.busy;
    return ItemCard(
      key: ValueKey(item.type),
      item: item,
      focused: pending && state.focused == item.type,
      docsLocked: h.onDocuments == null,
      actions: ItemActions(
        decide: pending && h.onApprove != null,
        onFocus: pending ? () => h.onFocus(item.type) : null,
        onApprove: idle ? () => h.onApprove?.call(item.type) : null,
        onReject: idle ? () => h.onReject?.call(item.type) : null,
        onDocuments: () => h.onDocuments?.call(item),
      ),
    );
  }
}
