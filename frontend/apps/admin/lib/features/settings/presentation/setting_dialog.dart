import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/form_dialog.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Longest setting value the API accepts.
const maxSettingLength = 20000;

/// Why [value] is not a valid [type] setting, or null when it is.
String? checkSetting(AdminL10n t, SettingTypeEnum type, String value) {
  final text = value.trim();
  if (text.length > maxSettingLength) return t.formTooLong('$maxSettingLength');
  return switch (type) {
    SettingTypeEnum.integer => int.tryParse(text) == null ? t.formWhole : null,
    SettingTypeEnum.number =>
      double.tryParse(text) == null ? t.formNumber : null,
    SettingTypeEnum.geojson => _isShape(text) ? null : t.settingsBadShape,
    _ => null,
  };
}

bool _isShape(String text) {
  try {
    final shape = jsonDecode(text);
    return shape is Map<String, Object?> && shape['type'] is String;
  } on FormatException {
    return false;
  }
}

/// Opens the editor for [setting]; resolves with true once saved.
Future<bool?> showSettingDialog(
  BuildContext context, {
  required SettingsCubit cubit,
  required Setting setting,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _SettingDialog(cubit: cubit, setting: setting),
);

class _SettingDialog extends StatefulWidget {
  const _SettingDialog({required this.cubit, required this.setting});

  final SettingsCubit cubit;
  final Setting setting;

  @override
  State<_SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<_SettingDialog> {
  late final _value = TextEditingController(text: widget.setting.value);
  late bool _on = widget.setting.value == 'true';
  String? _error;
  var _busy = false;

  bool get _isSwitch => widget.setting.type == SettingTypeEnum.boolean;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final type = widget.setting.type;
    final value = _isSwitch ? '$_on' : _value.text.trim();
    final problem = checkSetting(context.t, type, value);
    if (problem != null) return setState(() => _error = problem);
    setState(() => _busy = true);
    final failure = await widget.cubit.update(widget.setting.key, value);
    if (!mounted) return;
    if (failure == null) return Navigator.pop(context, true);
    setState(() {
      _busy = false;
      _error = context.failureText(failure);
    });
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.setting.key,
    busy: _busy,
    onSave: _save,
    children: _fields(context),
  );

  List<Widget> _fields(BuildContext context) => [
    Text(widget.setting.description),
    if (_isSwitch)
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.t.settingsOn),
        value: _on,
        onChanged: (v) => setState(() => _on = v),
      )
    else
      PaoTextField(
        label: context.t.settingsValue,
        controller: _value,
        maxLines: widget.setting.type == SettingTypeEnum.geojson ? 8 : 1,
      ),
    if (_error != null) FormError(_error!),
    PaoBanner(message: context.t.settingsApplyNow, icon: Icons.info_outline),
  ];
}
