import 'package:flutter/material.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Filters over the audit log: actor ID, action, subject ID and a date range
/// in Dhaka days.
class AuditFilters extends StatefulWidget {
  /// Creates the filters showing [filter].
  const AuditFilters({
    required this.filter,
    required this.now,
    required this.onApply,
    super.key,
  });

  /// The filter in force.
  final AuditFilter filter;

  /// Current time, the latest date offered.
  final DateTime Function() now;

  /// Runs the log with a new filter.
  final ValueChanged<AuditFilter> onApply;

  @override
  State<AuditFilters> createState() => _AuditFiltersState();
}

class _AuditFiltersState extends State<AuditFilters> {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  late final _actor = TextEditingController(text: widget.filter.actorId);
  late final _action = TextEditingController(text: widget.filter.action);
  late final _subject = TextEditingController(text: widget.filter.subjectId);
  late DateTime? _from = widget.filter.from;
  late DateTime? _to = widget.filter.to;
  String? _actorError;

  @override
  void dispose() {
    _actor.dispose();
    _action.dispose();
    _subject.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _apply() {
    final actor = _text(_actor);
    final bad = actor != null && !_uuid.hasMatch(actor);
    setState(() => _actorError = bad ? context.t.auditActorInvalid : null);
    if (bad) return;
    widget.onApply(
      AuditFilter(
        actorId: actor,
        action: _text(_action),
        subjectId: _text(_subject),
        from: _from,
        to: _to,
      ),
    );
  }

  Future<void> _pickDates() async {
    final now = widget.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (range == null) return;
    setState(() {
      // Dates are Dhaka days; midnight there is 18:00 UTC the day before.
      _from = _dhakaMidnight(range.start);
      _to = _dhakaMidnight(range.end.add(const Duration(days: 1)))
          .subtract(const Duration(seconds: 1));
    });
  }

  String _day(BuildContext context, DateTime at) => context.when(at, 'd MMM y');

  DateTime _dhakaMidnight(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day).subtract(dhakaOffset);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final from = _from;
    final to = _to;
    return FilterBar(
      filters: [
        _field(_actor, t.auditActorId, error: _actorError),
        _field(_action, t.auditActionHint),
        _field(_subject, t.auditSubjectId),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(
            from == null || to == null
                ? t.auditAnyDate
                : '${_day(context, from)} – ${_day(context, to)}',
          ),
          onPressed: _pickDates,
        ),
        PaoButton(label: t.auditApply, expand: false, onPressed: _apply),
        TextButton(
          onPressed: () => widget.onApply(const AuditFilter()),
          child: Text(t.auditClear),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    String? error,
  }) => SizedBox(
    width: 220,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hint, errorText: error),
      onSubmitted: (_) => _apply(),
    ),
  );
}
