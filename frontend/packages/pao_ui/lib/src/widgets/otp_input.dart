import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// One-time code entry as a row of boxes over a single hidden field, so paste
/// and SMS autofill work (C04).
class PaoOtpInput extends StatefulWidget {
  /// Creates the input; [onCompleted] fires once [length] digits are entered.
  const PaoOtpInput({
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.semanticLabel = 'One-time code',
    super.key,
  });

  /// Called with the full code.
  final ValueChanged<String> onCompleted;

  /// Number of digits.
  final int length;

  /// Shows the boxes in red (C33 wrong code).
  final bool hasError;

  /// Label read by screen readers.
  final String semanticLabel;

  @override
  State<PaoOtpInput> createState() => _PaoOtpInputState();
}

class _PaoOtpInputState extends State<PaoOtpInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    if (value.length == widget.length) widget.onCompleted(value);
  }

  Widget _box(BuildContext context, int i) {
    final code = _controller.text;
    final color = widget.hasError
        ? PaoColors.danger
        : (i == code.length ? context.pao.accent.primary : PaoColors.border);
    return Container(
      width: minTapTarget,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PaoColors.surface,
        borderRadius: BorderRadius.circular(PaoRadius.md),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        i < code.length ? code[i] : '',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (var i = 0; i < widget.length; i++) _box(context, i)],
        ),
      ),
      Positioned.fill(
        child: Opacity(
          opacity: 0,
          alwaysIncludeSemantics: true,
          child: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _changed,
            decoration: InputDecoration(
              counterText: '',
              labelText: widget.semanticLabel,
            ),
          ),
        ),
      ),
    ],
  );
}
