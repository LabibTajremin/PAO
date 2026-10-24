import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pao_admin/features/level2/presentation/level2_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Longest note the API accepts.
const maxNotes = 1000;

/// Records a session: passed or not per checklist item, an overall result and
/// notes. Items start from the service's checklist; more can be added.
class ResultForm extends StatefulWidget {
  /// Creates the form.
  const ResultForm({
    required this.template,
    required this.onSubmit,
    this.busy = false,
    this.error,
    super.key,
  });

  /// Checklist items to start from.
  final List<String> template;

  /// Saves the result.
  final ValueChanged<Level2ResultInput> onSubmit;

  /// Saving is in flight.
  final bool busy;

  /// Why the last save failed.
  final String? error;

  @override
  State<ResultForm> createState() => _ResultFormState();
}

class _ResultFormState extends State<ResultForm> {
  late final List<({String item, bool passed})> _lines = [
    for (final i in widget.template) (item: i, passed: false),
  ];
  final _newItem = TextEditingController();
  final _notes = TextEditingController();
  Level2Result? _result;
  String? _problem;

  @override
  void dispose() {
    _newItem.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _add() {
    final item = _newItem.text.trim();
    if (item.isEmpty) return;
    setState(() => _lines.add((item: item, passed: false)));
    _newItem.clear();
  }

  void _toggle(int i, bool passed) =>
      setState(() => _lines[i] = (item: _lines[i].item, passed: passed));

  void _submit() {
    final t = context.t;
    final result = _result;
    final problem = _lines.isEmpty
        ? t.level2NeedChecklist
        : result == null
        ? t.level2NeedResult
        : null;
    setState(() => _problem = problem);
    if (result == null || problem != null) return;
    final notes = _notes.text.trim();
    widget.onSubmit(
      Level2ResultInput(
        result: result,
        checklist: [
          for (final l in _lines)
            Level2ResultInputChecklistInner(item: l.item, passed: l.passed),
        ],
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final error = _problem ?? widget.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaoSpace.sm,
      children: [
        Text(t.level2Checklist, style: Theme.of(context).textTheme.titleMedium),
        for (final (i, l) in _lines.indexed)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.item),
            subtitle: Text(l.passed ? t.level2ItemPassed : t.level2ItemFailed),
            value: l.passed,
            onChanged: (v) => _toggle(i, v!),
          ),
        _AddItem(controller: _newItem, onAdd: _add),
        Text(t.level2Outcome, style: Theme.of(context).textTheme.titleMedium),
        _ResultChoice(
          selected: _result,
          onChanged: (r) => setState(() => _result = r),
        ),
        PaoTextField(
          label: t.level2Notes,
          controller: _notes,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(maxNotes)],
        ),
        if (error != null)
          Text(error, style: const TextStyle(color: PaoColors.danger)),
        PaoButton(
          label: t.level2Record,
          loading: widget.busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _ResultChoice extends StatelessWidget {
  const _ResultChoice({required this.selected, required this.onChanged});

  final Level2Result? selected;
  final ValueChanged<Level2Result> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.sm,
    children: [
      for (final r in Level2Result.values)
        PaoChip(
          label: resultLabel(context.t, r),
          selected: selected == r,
          onTap: () => onChanged(r),
        ),
    ],
  );
}

class _AddItem extends StatelessWidget {
  const _AddItem({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    spacing: PaoSpace.sm,
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.t.level2AddItem),
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
          onSubmitted: (_) => onAdd(),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: context.t.level2AddItem,
        onPressed: onAdd,
      ),
    ],
  );
}
