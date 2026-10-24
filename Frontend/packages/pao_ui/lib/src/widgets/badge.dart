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

/// A small status pill such as "Verified" or "Cancelled", led by a dot (or
/// [icon]) so the tone is not carried by colour alone.
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
    final c = context.pao;
    final fg = switch (tone) {
      PaoTone.neutral => c.inkMuted,
      PaoTone.accent => c.selectedInk,
      PaoTone.success => c.successInk,
      PaoTone.warning => c.warningInk,
      PaoTone.danger => c.dangerInk,
    };
    final bg = tone == PaoTone.accent
        ? c.selectedFill
        : fg.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        PaoSpace.sm + 2,
        PaoSpace.xs,
        PaoSpace.md,
        PaoSpace.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(PaoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: fg)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          const SizedBox(width: PaoSpace.xs + 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
