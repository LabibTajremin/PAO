import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// One headline number on the dashboard; [onTap] opens its queue.
class KpiTile extends StatelessWidget {
  /// Creates the tile.
  const KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  /// Icon beside the number.
  final IconData icon;

  /// What the number counts.
  final String label;

  /// The formatted number.
  final String value;

  /// Opens the related screen; null when the admin may not see it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: PaoCard(
        onTap: onTap,
        child: Row(
          children: [
            PaoIconTile(icon: icon, size: 40),
            const SizedBox(width: PaoSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: text.headlineSmall),
                  Text(
                    label,
                    style: text.bodySmall!.copyWith(
                      color: PaoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
