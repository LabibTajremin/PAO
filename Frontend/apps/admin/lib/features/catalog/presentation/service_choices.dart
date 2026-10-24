import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/features/catalog/presentation/service_draft.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Category, service model and required level of a service.
class ServiceChoices extends StatelessWidget {
  /// Creates the choices.
  const ServiceChoices({
    required this.draft,
    required this.categories,
    required this.onChanged,
    super.key,
  });

  /// The form values.
  final ServiceDraft draft;

  /// Categories to file the service under.
  final List<Category> categories;

  /// Rebuilds the form after a choice.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.lg,
    runSpacing: PaoSpace.lg,
    children: [
      for (final field in [
        _category(context),
        _model(context),
        _level(context),
      ])
        SizedBox(width: 300, child: field),
    ],
  );

  Widget _category(BuildContext context) => DropdownButtonFormField<String>(
    isExpanded: true,
    initialValue: draft.categoryId,
    decoration: InputDecoration(
      labelText: context.t.catalogCategory,
      errorText: draft.categoryError,
    ),
    items: [
      for (final c in categories)
        DropdownMenuItem(value: c.id, child: Text(context.local(c.name))),
    ],
    onChanged: (id) => _set(() => draft.categoryId = id),
  );

  Widget _model(BuildContext context) => DropdownButtonFormField<ServiceModel>(
    isExpanded: true,
    initialValue: draft.model,
    decoration: InputDecoration(labelText: context.t.catalogModel),
    items: [
      for (final m in ServiceModel.values)
        DropdownMenuItem(value: m, child: Text(modelLabel(context.t, m))),
    ],
    onChanged: (m) => _set(() => draft.model = m!),
  );

  Widget _level(BuildContext context) => DropdownButtonFormField<int>(
    isExpanded: true,
    initialValue: draft.level,
    decoration: InputDecoration(labelText: context.t.catalogLevel),
    items: [
      for (final l in [0, 1, 2])
        DropdownMenuItem(value: l, child: Text(levelName(context.t, l))),
    ],
    onChanged: (l) => _set(() => draft.level = l!),
  );

  void _set(VoidCallback change) {
    change();
    onChanged();
  }
}
