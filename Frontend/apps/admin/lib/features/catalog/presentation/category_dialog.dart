import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/icon_key_field.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Opens the category form: a new category when [category] is null. Resolves
/// with true once saved.
Future<bool?> showCategoryDialog(
  BuildContext context, {
  required CatalogCubit cubit,
  Category? category,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _CategoryDialog(cubit: cubit, category: category),
);

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.cubit, this.category});

  final CatalogCubit cubit;
  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final _name = LocalizedInput(widget.category?.name);
  late final _icon = TextEditingController(text: widget.category?.iconKey);
  late final _sort = TextEditingController(
    text: '${widget.category?.sortOrder ?? 0}',
  );
  late bool _published = widget.category?.published ?? false;
  final _errors = FormErrors();
  var _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    _name.check(t, _errors);
    _errors
      ..set(_icon, checkText(t, _icon.text, max: 40))
      ..set(_sort, checkWhole(t, _sort.text, min: 0));
    if (!_errors.isEmpty) return setState(() {});
    setState(() => _busy = true);
    final failure = await widget.cubit.saveCategory(
      widget.category?.id,
      CategoryInput(
        name: _name.value,
        iconKey: _icon.text.trim(),
        sortOrder: int.parse(_sort.text.trim()),
        published: _published,
      ),
    );
    if (!mounted) return;
    if (failure == null) return Navigator.pop(context, true);
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.category == null
        ? context.t.catalogNewCategory
        : context.t.catalogEditCategory,
    busy: _busy,
    onSave: _save,
    children: _fields(context),
  );

  List<Widget> _fields(BuildContext context) {
    final t = context.t;
    return [
      LocalizedFields(input: _name, label: t.catalogName, errors: _errors),
      IconKeyField(controller: _icon, error: _errors.of(_icon)),
      PaoTextField(
        label: t.catalogSortOrder,
        controller: _sort,
        keyboardType: TextInputType.number,
        error: _errors.of(_sort),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t.catalogPublishedSwitch),
        subtitle: Text(t.catalogPublishedHint),
        value: _published,
        onChanged: (v) => setState(() => _published = v),
      ),
      if (_failure != null) FormError(context.failureText(_failure)!),
    ];
  }
}
