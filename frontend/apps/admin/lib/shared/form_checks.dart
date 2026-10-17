import 'package:flutter/widgets.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';

/// Field errors of a form, keyed by the field's controller, so a field reads
/// its own message with [of].
class FormErrors {
  final _errors = <TextEditingController, String>{};

  /// The message for [field], or null.
  String? of(TextEditingController field) => _errors[field];

  /// Records [problem] for [field], or clears it when null.
  void set(TextEditingController field, String? problem) {
    if (problem == null) {
      _errors.remove(field);
    } else {
      _errors[field] = problem;
    }
  }

  /// No field has a problem.
  bool get isEmpty => _errors.isEmpty;

  /// Forgets every problem, e.g. before checking a form whose rows changed.
  void clear() => _errors.clear();
}

/// A text the API accepts between 1 and [max] characters.
String? checkText(AdminL10n t, String text, {int max = 200}) {
  final value = text.trim();
  if (value.isEmpty) return t.formRequired;
  return value.length > max ? t.formTooLong('$max') : null;
}

/// A whole number from [min] to [max] (no upper bound when null).
String? checkWhole(AdminL10n t, String text, {required int min, int? max}) {
  final value = text.trim();
  if (value.isEmpty) return t.formRequired;
  final n = int.tryParse(value);
  if (n == null) return t.formWhole;
  if (n < min || (max != null && n > max)) {
    return max == null ? t.formAtLeast('$min') : t.formRange('$min', '$max');
  }
  return null;
}

/// A taka amount such as `500` or `499.50` in paisa, or null if it is not
/// one.
int? parsePaisa(String text) {
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(text.trim());
  if (match == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return int.parse(match.group(1)!) * 100 + int.parse(fraction);
}

/// A taka amount the API accepts as a price.
String? checkMoney(AdminL10n t, String text) {
  if (text.trim().isEmpty) return t.formRequired;
  return parsePaisa(text) == null ? t.formMoney : null;
}
