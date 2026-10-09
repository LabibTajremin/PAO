import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// Colour family of a [PaoBadge].
enum PaoTone {
  /// Grey.
  neutral,

  /// The accent.
  accent,

  /// Green.
  success,

  /// Amber.
  warning,

  /// Red.
  danger,
}

/// A small status pill such as "Verified" or "Cancelled".
class PaoBadge extends StatelessWidget {
  /// Creates a badge.
  const PaoBadge({
    required this.label,
    this.tone = PaoTone.neutral,
    this.icon,
    super.key,
  });

  /// Badge text.
  final String label;

  /// Colour family.
  final PaoTone tone;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final fg = switch (tone) {
      PaoTone.neutral => PaoColors.textSecondary,
      PaoTone.accent => accent.strong,
      PaoTone.success => PaoColors.success,
      PaoTone.warning => PaoColors.warning,
      PaoTone.danger => PaoColors.danger,
    };
    final bg = tone == PaoTone.accent ? accent.soft : fg.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PaoSpace.sm + 2,
        vertical: PaoSpace.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(PaoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: PaoSpace.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
