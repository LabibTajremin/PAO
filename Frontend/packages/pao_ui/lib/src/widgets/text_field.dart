import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A labelled text field with an optional error below it. An [obscureText]
/// field carries an eye button that shows and hides what was typed.
class PaoTextField extends StatefulWidget {
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
    this.obscureText = false,
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

  /// Hides the text, for passwords.
  final bool obscureText;

  @override
  State<PaoTextField> createState() => _PaoTextFieldState();
}

class _PaoTextFieldState extends State<PaoTextField> {
  var _shown = false;

  Widget? _eye(BuildContext context) {
    if (!widget.obscureText) return null;
    final t = PaoL10n.of(context);
    return IconButton(
      tooltip: _shown ? t.actionHidePassword : t.actionShowPassword,
      icon: Icon(
        _shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: () => setState(() => _shown = !_shown),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium!
              .copyWith(color: context.pao.inkMuted),
        ),
        const SizedBox(height: PaoSpace.sm),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          obscureText: widget.obscureText && !_shown,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.error,
            prefixText: widget.prefix == null ? null : '${widget.prefix} ',
            suffixIcon: _eye(context),
            semanticCounterText: widget.label,
          ),
        ),
      ],
    );
  }
}
