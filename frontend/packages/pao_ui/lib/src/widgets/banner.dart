import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A full-width strip for app-wide notices such as being offline (C36).
class PaoBanner extends StatelessWidget {
  /// Creates the banner.
  const PaoBanner({
    required this.message,
    this.icon = Icons.wifi_off,
    super.key,
  });

  /// Notice text.
  final String message;

  /// Leading icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Material(
      color: context.pao.accent.deep,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PaoSpace.lg,
          vertical: PaoSpace.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: PaoColors.onPrimary),
            const SizedBox(width: PaoSpace.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall!
                    .copyWith(color: PaoColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
