import 'package:flutter/material.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Counts per key (status, level) with a bar showing each one's share.
class BreakdownCard extends StatelessWidget {
  /// Creates the card.
  const BreakdownCard({
    required this.title,
    required this.counts,
    required this.label,
    super.key,
  });

  /// Heading.
  final String title;

  /// Count per key, in the order the API sent them.
  final Map<String, int> counts;

  /// Names a key.
  final String Function(String key) label;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (sum, n) => sum + n);
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: PaoSpace.md),
          if (total == 0)
            Text(context.t.dashNoProviders)
          else
            for (final MapEntry(:key, :value) in counts.entries)
              _Row(
                label: label(key),
                count: context.count(value),
                share: value / total,
              ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.count, required this.share});

  final String label;
  final String count;
  final double share;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: PaoSpace.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(count, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: PaoSpace.xs),
        LinearProgressIndicator(
          value: share,
          minHeight: 6,
          borderRadius: BorderRadius.circular(PaoRadius.sm),
          backgroundColor: PaoColors.border,
          color: context.pao.accent.primary,
        ),
      ],
    ),
  );
}
