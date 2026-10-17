import 'package:flutter/material.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Asks for a new bio starting from [current]; null when cancelled.
Future<String?> showBioSheet(BuildContext context, String current) =>
    showPaoSheet<String>(
      context,
      title: context.t.profEditBio,
      child: _BioForm(current: current),
    );

class _BioForm extends StatefulWidget {
  const _BioForm({required this.current});

  final String current;

  @override
  State<_BioForm> createState() => _BioFormState();
}

class _BioFormState extends State<_BioForm> {
  late final _bio = TextEditingController(text: widget.current);
  String? _error;

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    // ProviderProfileUpdate.bio allows at most 500 characters.
    if (_bio.text.trim().length > 500) {
      return setState(() => _error = context.t.profBioTooLong);
    }
    Navigator.of(context).pop(_bio.text);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PaoTextField(
        label: context.t.profBioLabel,
        controller: _bio,
        hint: context.t.profBioHint,
        maxLines: 4,
        error: _error,
      ),
      const SizedBox(height: PaoSpace.lg),
      PaoButton(label: context.common.actionSave, onPressed: _save),
    ],
  );
}
