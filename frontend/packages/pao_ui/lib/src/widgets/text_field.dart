import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A labelled text field with an optional error below it.
class PaoTextField extends StatelessWidget {
  /// Creates a field.
  const PaoTextField({
    required this.label,
    this.controller,
    this.hint,
    this.error,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.maxLines = 1,
    super.key,
  });

  /// Label above the field.
  final String label;

  /// Holds the text.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? hint;

  /// Error shown under the field; null when valid.
  final String? error;

  /// Fixed text before the input, such as `+880`.
  final String? prefix;

  /// Keyboard to show.
  final TextInputType? keyboardType;

  /// Input restrictions, e.g. digits only.
  final List<TextInputFormatter>? inputFormatters;

  /// Called on each edit.
  final ValueChanged<String>? onChanged;

  /// Number of visible lines.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: PaoSpace.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            prefixText: prefix == null ? null : '$prefix ',
            semanticCounterText: label,
          ),
        ),
      ],
    );
  }
}
