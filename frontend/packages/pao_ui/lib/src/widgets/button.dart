import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// Visual weight of a [PaoButton].
enum PaoButtonVariant {
  /// Filled with the accent; one per screen.
  primary,

  /// Accent-tinted fill for secondary actions.
  soft,

  /// Bordered, for neutral choices.
  outline,

  /// Text only, for tertiary actions.
  ghost,

  /// Red, for destructive actions such as cancelling.
  danger,
}

/// The PAO button. A null [onPressed] disables it; [loading] shows a spinner
/// and blocks taps so a slow network cannot double-submit.
class PaoButton extends StatelessWidget {
  /// Creates a button.
  const PaoButton({
    required this.label,
    required this.onPressed,
    this.variant = PaoButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    super.key,
  });

  /// Button text.
  final String label;

  /// Tap handler; null disables the button.
  final VoidCallback? onPressed;

  /// Visual weight.
  final PaoButtonVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  /// Shows a spinner instead of the label.
  final bool loading;

  /// Fills the available width.
  final bool expand;

  (Color, Color, BorderSide?) _colors(AccentPreset accent) => switch (variant) {
    PaoButtonVariant.primary => (accent.primary, PaoColors.onPrimary, null),
    PaoButtonVariant.soft => (accent.soft, accent.strong, null),
    PaoButtonVariant.outline => (
      PaoColors.surface,
      PaoColors.textPrimary,
      const BorderSide(color: PaoColors.border),
    ),
    PaoButtonVariant.ghost => (Colors.transparent, accent.primary, null),
    PaoButtonVariant.danger => (PaoColors.danger, PaoColors.onPrimary, null),
  };

  Widget _content(Color fg) => loading
      ? SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: fg),
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: PaoSpace.sm),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        );

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = _colors(context.pao.accent);
    return Semantics(
      button: true,
      label: loading ? label : null,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          disabledForegroundColor: fg.withValues(alpha: 0.7),
          side: side,
          minimumSize: Size(expand ? double.infinity : minTapTarget, 52),
          padding: const EdgeInsets.symmetric(horizontal: PaoSpace.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PaoRadius.md),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: _content(fg),
      ),
    );
  }
}
