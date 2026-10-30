import 'package:flutter/material.dart' hide Badge;
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/providers/presentation/provider_labels.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One review: stars, author, date, service, comment and tags.
class ReviewCard extends StatelessWidget {
  /// Creates the card.
  const ReviewCard({required this.review, super.key});

  /// The review.
  final Review review;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final service = review.serviceName;
    final comment = review.comment ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        child: Column(
          spacing: PaoSpace.xs,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaoRatingStars(
              rating: review.stars.toDouble(),
              size: 16,
              semanticLabel: context.common.ratingLabel(
                context.count(review.stars),
              ),
            ),
            Text(
              [
                review.authorName,
                context.when(review.createdAt, 'd MMM y'),
              ].join(' · '),
              style: text.titleSmall,
            ),
            if (service != null)
              Text(context.local(service), style: text.bodySmall),
            if (comment.isNotEmpty) Text(comment),
            Wrap(
              spacing: PaoSpace.xs,
              runSpacing: PaoSpace.xs,
              children: [
                for (final tag in review.tags)
                  PaoBadge(label: tagLabel(context.t, tag)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Average rating, count and how many reviews gave each star value.
class RatingSummary extends StatelessWidget {
  /// Creates the summary.
  const RatingSummary({required this.rating, super.key});

  /// The breakdown.
  final RatingBreakdown rating;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final average = rating.average.toStringAsFixed(1);
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: PaoSpace.md,
            children: [
              Text(average, style: text.headlineMedium),
              PaoRatingStars(
                rating: rating.average,
                semanticLabel: context.common.ratingLabel(average),
              ),
            ],
          ),
          Text(
            context.t.provRatingCount(
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

/// What the verification badges mean (C41).
Future<void> showBadgeSheet(BuildContext context) => showPaoSheet<void>(
  context,
  title: context.t.provBadgeSheet,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (badge, body) in [
        (Badge.verified, context.t.provBadgeVerifiedBody),
        (Badge.verifiedPro, context.t.provBadgeProBody),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: PaoSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PaoSpace.xs,
            children: [
              PaoBadge(
                label: badgeLabel(context.t, badge),
                tone: badgeTone(badge),
                icon: Icons.verified_outlined,
              ),
              Text(body),
            ],
          ),
        ),
    ],
  ),
);
