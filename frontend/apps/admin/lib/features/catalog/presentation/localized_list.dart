import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// An editable list of texts in both languages, such as a Level 2 checklist
/// or a sub-service's inclusions; [onChanged] rebuilds the owning form.
class LocalizedList extends StatelessWidget {
  /// Creates the list.
  const LocalizedList({
    required this.title,
    required this.items,
    required this.errors,
    required this.onChanged,
    super.key,
  });

  /// Heading, also the label of each row.
  final String title;

  /// The rows; added and removed in place.
  final List<LocalizedInput> items;

  /// Field errors.
  final FormErrors errors;

  /// Called after a row is added or removed.
  final VoidCallback onChanged;

  void _add() {
    items.add(LocalizedInput());
    onChanged();
  }

  void _remove(LocalizedInput item) {
    items.remove(item);
    onChanged();
    // The fields still hold the controllers until this frame is rebuilt.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: PaoSpace.sm,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          TextButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(context.t.catalogAddRow),
          ),
        ],
      ),
      for (final (i, item) in items.indexed)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LocalizedFields(
                input: item,
                label: '$title ${i + 1}',
                errors: errors,
              ),
            ),
            IconButton(
              tooltip: context.t.catalogRemoveRow,
              onPressed: () => _remove(item),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
    ],
  );
}
