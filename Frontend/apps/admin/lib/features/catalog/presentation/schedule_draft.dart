import 'package:flutter/widgets.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_api/pao_api.dart';

/// The ordering rules of a scheduled-delivery service while the admin edits
/// them (ADR-0041 §1); unused for the other models.
class ScheduleDraft {
  /// Starts from [schedule], or from the office-lunch defaults.
  ScheduleDraft(ServiceSchedule? schedule)
    : patterns = {...?schedule?.patterns},
      windows = TextEditingController(
        text: (schedule?.windows ?? const [])
            .map((w) => '${w.start}-${w.end}')
            .join(', '),
      ),
      lead = TextEditingController(text: '${schedule?.leadHours ?? 12}'),
      cutoff = TextEditingController(text: schedule?.cutoff ?? '20:00'),
      unit = schedule?.unit ?? QuantityUnit.meals,
      min = TextEditingController(text: '${schedule?.minQuantity ?? 1}'),
      max = TextEditingController(text: '${schedule?.maxQuantity ?? 50}');

  /// The patterns customers may choose.
  final Set<DeliveryPattern> patterns;

  /// The windows, written `12:00-13:00, 19:00-21:00`.
  final TextEditingController windows;

  /// The lead time in hours.
  final TextEditingController lead;

  /// The cutoff on the day before, `HH:MM`.
  final TextEditingController cutoff;

  /// What the quantity counts.
  QuantityUnit unit;

  /// The smallest and largest quantity.
  final TextEditingController min;

  /// The largest quantity.
  final TextEditingController max;

  /// Set when no pattern is chosen.
  String? patternError;

  static final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  List<DeliveryWindow>? get _windows {
    final parts = windows.text.split(',').map((w) => w.trim().split('-'));
    final list = [
      for (final p in parts)
        if (p.length == 2 &&
            _time.hasMatch(p[0].trim()) &&
            _time.hasMatch(p[1].trim()))
          DeliveryWindow(start: p[0].trim(), end: p[1].trim()),
    ];
    final ordered = list.every((w) => w.start.compareTo(w.end) < 0);
    return list.isNotEmpty && list.length == parts.length && ordered
        ? list
        : null;
  }

  /// Checks the rules like the API does into [errors]; true when they can be
  /// sent.
  bool check(AdminL10n t, FormErrors errors) {
    patternError = patterns.isEmpty ? t.catalogPatternsRequired : null;
    errors
      ..set(windows, _windows == null ? t.catalogTimeFormat : null)
      ..set(
        cutoff,
        _time.hasMatch(cutoff.text.trim()) ? null : t.catalogTimeFormat,
      )
      ..set(lead, checkWhole(t, lead.text, min: 0, max: 336))
      ..set(min, checkWhole(t, min.text, min: 1, max: 500))
      ..set(
        max,
        checkWhole(
          t,
          max.text,
          min: int.tryParse(min.text.trim()) ?? 1,
          max: 500,
        ),
      );
    return patternError == null;
  }

  /// The rules as the API takes them; call after [check] passed.
  ServiceSchedule toSchedule() => ServiceSchedule(
    patterns: {
      for (final p in DeliveryPattern.values)
        if (patterns.contains(p)) p,
    },
    windows: _windows!,
    leadHours: int.parse(lead.text.trim()),
    cutoff: cutoff.text.trim(),
    unit: unit,
    minQuantity: int.parse(min.text.trim()),
    maxQuantity: int.parse(max.text.trim()),
  );

  /// Releases the controllers.
  void dispose() {
    for (final c in [windows, lead, cutoff, min, max]) {
      c.dispose();
    }
  }
}
