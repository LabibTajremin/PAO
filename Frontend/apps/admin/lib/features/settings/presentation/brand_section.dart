import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// The tagline setting's key (06-update §6, ADR-0040).
const taglineKey = 'brand.tagline';

/// The most characters per language.
const maxTaglineLength = 40;

/// Lines shown to the owner as suggestions, by language.
const taglineSuggestions = {
  'bn': ['যা চাও, তাই PAO', 'চাও it, PAO it', 'চাইলেই PAO'],
  'en': ['Ask for it. PAO it.', 'Need it? PAO it.'],
};

/// The tagline as stored: `{"en": …, "bn": …}`; empty strings when unreadable.
({String en, String bn}) readTagline(String json) {
  try {
    final value = jsonDecode(json);
    if (value is Map<String, Object?>) {
      return (en: '${value['en'] ?? ''}', bn: '${value['bn'] ?? ''}');
    }
  } on FormatException {
    // A damaged value starts the editor empty; saving replaces it.
  }
  return (en: '', bn: '');
}

/// Settings › Brand: the tagline in both languages with a live preview on the
/// wordmark and the suggestion chips.
class BrandSection extends StatefulWidget {
  /// Creates the section for the stored [setting].
  const BrandSection({
    required this.setting,
    required this.cubit,
    required this.canEdit,
    super.key,
  });

  /// The `brand.tagline` setting.
  final Setting setting;

  /// Saves the setting.
  final SettingsCubit cubit;

  /// The admin holds `settings:manage`.
  final bool canEdit;

  @override
  State<BrandSection> createState() => _BrandSectionState();
}

class _BrandSectionState extends State<BrandSection> {
  late final ({String en, String bn}) _stored = readTagline(
    widget.setting.value,
  );
  late final _en = TextEditingController(text: _stored.en);
  late final _bn = TextEditingController(text: _stored.bn);
  String? _enError;
  String? _bnError;
  AppFailure? _failure;

  @override
  void dispose() {
    _en.dispose();
    _bn.dispose();
    super.dispose();
  }

  String? _check(String text) {
    final t = context.t;
    if (text.trim().isEmpty) return t.formRequired;
    if (text.trim().runes.length > maxTaglineLength) {
      return t.formTooLong('$maxTaglineLength');
    }
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _enError = _check(_en.text);
      _bnError = _check(_bn.text);
    });
    if (_enError != null || _bnError != null) return;
    final value = jsonEncode({'en': _en.text.trim(), 'bn': _bn.text.trim()});
    final failure = await widget.cubit.update(taglineKey, value);
    if (!mounted) return;
    setState(() => _failure = failure);
    if (failure == null) showDone(context, context.t.formSaved);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PaoCard(
      child: ListenableBuilder(
        listenable: Listenable.merge([_en, _bn]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaoSpace.md,
          children: [
            Text(
              t.settingsBrand,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _Preview(en: _en.text, bn: _bn.text),
            for (final (lang, controller, label, error) in [
              ('en', _en, t.settingsTaglineEn, _enError),
              ('bn', _bn, t.settingsTaglineBn, _bnError),
            ]) ...[
              PaoTextField(label: label, controller: controller, error: error),
              if (widget.canEdit)
                Wrap(
                  spacing: PaoSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(t.settingsTaglineSuggestions),
                    for (final line in taglineSuggestions[lang]!)
                      ActionChip(
                        label: Text(line),
                        onPressed: () => controller.text = line,
                      ),
                  ],
                ),
            ],
            Text(
              t.settingsTaglineHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (context.failureText(_failure) case final text?)
              Text(text, style: TextStyle(color: context.pao.dangerInk)),
            if (widget.canEdit)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(context.common.actionSave),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.en, required this.bn});

  final String en;
  final String bn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(PaoSpace.lg),
    decoration: BoxDecoration(
      color: context.pao.accent.primary,
      borderRadius: PaoShape.leafSmall,
    ),
    child: Column(
      spacing: PaoSpace.sm,
      children: [
        const PaoLogo(
          variant: PaoLogoVariant.wordmark,
          inverse: true,
          height: 32,
        ),
        for (final line in [en, bn])
          Text(line.trim(), style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
