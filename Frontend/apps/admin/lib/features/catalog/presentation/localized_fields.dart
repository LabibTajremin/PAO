import 'package:flutter/material.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Width from which the English and Bangla fields sit side by side.
const _sideBySide = 520.0;

/// The English and Bangla text of one catalog text.
class LocalizedInput {
  /// Creates the input, filled from [text] when given.
  LocalizedInput([LocalizedText? text])
    : en = TextEditingController(text: text?.en),
      bn = TextEditingController(text: text?.bn);

  /// English text.
  final TextEditingController en;

  /// Bangla text.
  final TextEditingController bn;

  /// Neither language is filled in.
  bool get isBlank => en.text.trim().isEmpty && bn.text.trim().isEmpty;

  /// The text as the API takes it.
  LocalizedText get value =>
      LocalizedText(en: en.text.trim(), bn: bn.text.trim());

  /// Checks both languages into [errors]; a blank [optional] text passes, but
  /// once one language is written the other is needed too.
  void check(AdminL10n t, FormErrors errors, {bool optional = false}) {
    final skip = optional && isBlank;
    errors
      ..set(en, skip ? null : checkText(t, en.text))
      ..set(bn, skip ? null : checkText(t, bn.text));
  }

  /// Releases the controllers.
  void dispose() {
    en.dispose();
    bn.dispose();
  }
}

/// The English and Bangla fields of a [LocalizedInput], side by side on wide
/// forms.
class LocalizedFields extends StatelessWidget {
  /// Creates the fields labelled with [label].
  const LocalizedFields({
    required this.input,
    required this.label,
    required this.errors,
    super.key,
  });

  /// The text being edited.
  final LocalizedInput input;

  /// What the text is, e.g. "Name".
  final String label;

  /// Field errors.
  final FormErrors errors;

  @override
  Widget build(BuildContext context) {
    final fields = [
      PaoTextField(
        label: context.t.catalogInEnglish(label),
        controller: input.en,
        error: errors.of(input.en),
      ),
      PaoTextField(
        label: context.t.catalogInBangla(label),
        controller: input.bn,
        error: errors.of(input.bn),
      ),
    ];
    return LayoutBuilder(
      builder: (_, box) => box.maxWidth >= _sideBySide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PaoSpace.md,
              children: [for (final f in fields) Expanded(child: f)],
            )
          : Column(spacing: PaoSpace.md, children: fields),
    );
  }
}
