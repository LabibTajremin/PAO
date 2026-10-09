import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A row in a settings or history list.
class PaoListRow extends StatelessWidget {
  /// Creates a row.
  const PaoListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// Main text.
  final String title;

  /// Secondary text.
  final String? subtitle;

  /// Widget before the text, e.g. an icon tile.
  final Widget? leading;

  /// Widget after the text; a chevron is shown when tappable and none is given.
  final Widget? trailing;

  /// Tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final end =
        trailing ??
        (onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: PaoColors.textTertiary));
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PaoSpace.lg,
            vertical: PaoSpace.md,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: PaoSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              ?end,
            ],
          ),
        ),
      ),
    );
  }
}
