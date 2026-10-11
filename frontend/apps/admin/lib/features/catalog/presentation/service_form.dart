import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/icon_key_field.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/features/catalog/presentation/service_choices.dart';
import 'package:pao_admin/features/catalog/presentation/service_draft.dart';
import 'package:pao_admin/features/catalog/presentation/service_switches.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// The service's own fields with a save button (A04).
class ServiceForm extends StatefulWidget {
  /// Creates the form; [categoryId] files a new service.
  const ServiceForm({
    required this.data,
    required this.cubit,
    this.categoryId,
    super.key,
  });

  /// Categories and the service being edited.
  final ServiceEditorData data;

  /// Saves the service.
  final ServiceEditorCubit cubit;

  /// Category a new service starts in.
  final String? categoryId;

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  late final _draft = ServiceDraft(
    widget.data.service,
    categoryId: widget.categoryId,
  );
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
    final (saved, failure) = await widget.cubit.saveService(
      widget.data.service?.id,
      _draft.toInput(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = failure;
    });
    if (failure != null) return;
    showDone(context, context.t.formSaved);
    if (widget.data.service == null) context.go(Routes.serviceOf(saved!.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaoSpace.lg,
        children: [
          Text(t.catalogServiceDetails, style: _heading(context)),
          ServiceChoices(
            draft: _draft,
            categories: widget.data.categories,
            onChanged: () => setState(() {}),
          ),
          LocalizedFields(
            input: _draft.name,
            label: t.catalogName,
            errors: _draft.errors,
          ),
          IconKeyField(
            controller: _draft.icon,
            error: _draft.errors.of(_draft.icon),
          ),
          PaoTextField(
            label: t.catalogRadius,
            hint: t.catalogRadiusHint,
            controller: _draft.radius,
            keyboardType: TextInputType.number,
            error: _draft.errors.of(_draft.radius),
          ),
          ServiceSwitches(draft: _draft, onChanged: () => setState(() {})),
          ..._footer(context),
        ],
      ),
    );
  }

  TextStyle? _heading(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;

  List<Widget> _footer(BuildContext context) => [
    if (_failure != null)
      Text(
        context.failureText(_failure)!,
        style: const TextStyle(color: PaoColors.danger),
      ),
    Align(
      alignment: Alignment.centerRight,
      child: PaoButton(
        label: context.common.actionSave,
        expand: false,
        loading: _busy,
        onPressed: _save,
      ),
    ),
  ];
}
