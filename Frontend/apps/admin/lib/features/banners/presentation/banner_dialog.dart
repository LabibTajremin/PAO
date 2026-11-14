import 'package:flutter/material.dart' hide Banner;
import 'package:pao_admin/features/banners/presentation/banners_cubit.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Opens the banner form: a new banner when [banner] is null. Resolves with
/// the message to show once saved or deleted.
Future<String?> showBannerDialog(
  BuildContext context, {
  required BannersCubit cubit,
  required List<Service> services,
  Banner? banner,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _BannerDialog(cubit: cubit, services: services, banner: banner),
);

class _BannerDialog extends StatefulWidget {
  const _BannerDialog({
    required this.cubit,
    required this.services,
    this.banner,
  });

  final BannersCubit cubit;
  final List<Service> services;
  final Banner? banner;

  @override
  State<_BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<_BannerDialog> {
  late final _title = LocalizedInput(widget.banner?.title);
  late final _subtitle = LocalizedInput(widget.banner?.subtitle);
  late final _image = TextEditingController(text: widget.banner?.imageUrl);
  late final _sort = TextEditingController(
    text: '${widget.banner?.sortOrder ?? 0}',
  );
  late String? _service = widget.banner?.serviceId;
  late bool _published = widget.banner?.published ?? false;
  final _errors = FormErrors();
  var _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _image.dispose();
    _sort.dispose();
    super.dispose();
  }

  String? _checkImage(String text) {
    final url = text.trim();
    if (url.isEmpty) return null;
    final ok =
        url.length <= 500 && (Uri.tryParse(url)?.isScheme('https') ?? false);
    return ok ? null : context.t.bannersImageInvalid;
  }

  Future<void> _run(Future<AppFailure?> Function() action, String done) async {
    setState(() => _busy = true);
    final failure = await action();
    if (!mounted) return;
    if (failure == null) return Navigator.pop(context, done);
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  Future<void> _save() async {
    final t = context.t;
    _title.check(t, _errors);
    _subtitle.check(t, _errors, optional: true);
    _errors
      ..set(_image, _checkImage(_image.text))
      ..set(_sort, checkWhole(t, _sort.text, min: -1000));
    if (!_errors.isEmpty) return setState(() {});
    final image = _image.text.trim();
    final input = BannerInput(
      title: _title.value,
      subtitle: _subtitle.isBlank ? null : _subtitle.value,
      imageUrl: image.isEmpty ? null : image,
      serviceId: _service,
      sortOrder: int.parse(_sort.text.trim()),
      published: _published,
    );
    await _run(() => widget.cubit.save(widget.banner?.id, input), t.formSaved);
  }

  Future<void> _delete() async {
    final t = context.t;
    final yes = await confirmAction(
      context,
      title: t.bannersDelete,
      body: context.local(widget.banner!.title),
      confirmLabel: t.bannersDelete,
    );
    if (!yes || !mounted) return;
    await _run(() => widget.cubit.delete(widget.banner!.id), t.bannersDeleted);
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.banner == null ? context.t.bannersNew : context.t.bannersEdit,
    busy: _busy,
    onSave: _save,
    children: _fields(context),
  );

  List<Widget> _fields(BuildContext context) {
    final t = context.t;
    return [
      LocalizedFields(input: _title, label: t.bannersHeadline, errors: _errors),
      LocalizedFields(
        input: _subtitle,
        label: t.bannersTagline,
        errors: _errors,
      ),
      PaoTextField(
        label: t.bannersImage,
        hint: t.bannersImageHint,
        controller: _image,
        keyboardType: TextInputType.url,
        error: _errors.of(_image),
      ),
      DropdownButtonFormField<String?>(
        isExpanded: true,
        initialValue: _service,
        decoration: InputDecoration(labelText: t.bannersService),
        items: [
          DropdownMenuItem(child: Text(t.bannersNoService)),
          for (final s in widget.services)
            DropdownMenuItem(value: s.id, child: Text(context.local(s.name))),
        ],
        onChanged: (id) => setState(() => _service = id),
      ),
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
      if (widget.banner != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _busy ? null : _delete,
            icon: Icon(Icons.delete_outline, color: context.pao.dangerInk),
            label: Text(
              t.bannersDelete,
              style: TextStyle(color: context.pao.dangerInk),
            ),
          ),
        ),
      if (_failure != null) FormError(context.failureText(_failure)!),
    ];
  }
}
