import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/features/catalog/presentation/localized_list.dart';
import 'package:pao_admin/features/catalog/presentation/sub_service_draft.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Opens the sub-service form under [serviceId]: a new one when [sub] is
/// null. Resolves with true once saved.
Future<bool?> showSubServiceDialog(
  BuildContext context, {
  required ServiceEditorCubit cubit,
  required String serviceId,
  SubService? sub,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _SubServiceDialog(
    cubit: cubit,
    draft: SubServiceDraft(serviceId, sub),
    id: sub?.id,
  ),
);

class _SubServiceDialog extends StatefulWidget {
  const _SubServiceDialog({required this.cubit, required this.draft, this.id});

  final ServiceEditorCubit cubit;
  final SubServiceDraft draft;
  final String? id;

  @override
  State<_SubServiceDialog> createState() => _SubServiceDialogState();
}

class _SubServiceDialogState extends State<_SubServiceDialog> {
  SubServiceDraft get _draft => widget.draft;
  var _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_draft.check(context.t)) return setState(() {});
    setState(() => _busy = true);
    final failure = await widget.cubit.saveSubService(
      widget.id,
      _draft.toInput(),
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
    title: _draft.isNew
        ? context.t.catalogNewSubService
        : context.t.catalogEditSub,
    width: 640,
    busy: _busy,
    onSave: _save,
    children: [..._texts(context), ..._terms(context)],
  );

  List<Widget> _texts(BuildContext context) {
    final t = context.t;
    void rebuild() => setState(() {});
    return [
      LocalizedFields(
        input: _draft.name,
        label: t.catalogName,
        errors: _draft.errors,
      ),
      LocalizedFields(
        input: _draft.description,
        label: t.catalogDescription,
        errors: _draft.errors,
      ),
      LocalizedList(
        title: t.catalogInclusion,
        items: _draft.inclusions,
        errors: _draft.errors,
        onChanged: rebuild,
      ),
      LocalizedList(
        title: t.catalogExclusion,
        items: _draft.exclusions,
        errors: _draft.errors,
        onChanged: rebuild,
      ),
    ];
  }

  List<Widget> _terms(BuildContext context) {
    final t = context.t;
    return [
      DropdownButtonFormField<PriceUnit>(
        isExpanded: true,
        initialValue: _draft.unit,
        decoration: InputDecoration(labelText: t.catalogUnit),
        items: [
          for (final u in PriceUnit.values)
            DropdownMenuItem(value: u, child: Text(unitLabel(t, u))),
        ],
        onChanged: (u) => _draft.unit = u!,
      ),
      PaoTextField(
        label: t.catalogMaxQuantity,
        hint: t.catalogMaxQuantityHint,
        controller: _draft.maxQuantity,
        keyboardType: TextInputType.number,
        error: _draft.errors.of(_draft.maxQuantity),
      ),
      if (_draft.isNew)
        PaoTextField(
          label: t.catalogFirstPrice,
          prefix: '৳',
          controller: _draft.price,
          keyboardType: TextInputType.number,
          error: _draft.errors.of(_draft.price),
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t.catalogPublishedSwitch),
        subtitle: Text(t.catalogPublishedHint),
        value: _draft.published,
        onChanged: (v) => setState(() => _draft.published = v),
      ),
      if (_failure != null) FormError(context.failureText(_failure)!),
    ];
  }
}
