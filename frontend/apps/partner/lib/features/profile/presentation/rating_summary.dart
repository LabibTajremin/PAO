import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Average rating, count and how many reviews gave each star value.
class RatingSummary extends StatelessWidget {
  /// Creates the summary.
  const RatingSummary({required this.rating, super.key});

  /// The breakdown.
  final RatingBreakdown rating;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating.average.toStringAsFixed(1),
                style: text.headlineMedium,
              ),
              const SizedBox(width: PaoSpace.md),
              PaoRatingStars(
                rating: rating.average,
                semanticLabel: context.common.ratingLabel(
                  rating.average.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          Text(
            context.t.profRatingCount(
              rating.count,
              context.count(rating.count),
            ),
          ),
          const SizedBox(height: PaoSpace.md),
          for (var star = 5; star >= 1; star--)
            _Bar(
              star: star,
              count: rating.distribution['$star'] ?? 0,
              total: rating.count,
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.star, required this.count, required this.total});

  final int star;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: PaoSpace.xs),
    child: Row(
      children: [
        SizedBox(width: 24, child: Text(context.count(star))),
        Expanded(
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : count / total,
            color: context.pao.accent.primary,
            backgroundColor: PaoColors.border,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(context.count(count), textAlign: TextAlign.end),
        ),
      ],
    ),
  );
}
