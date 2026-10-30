import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/providers/presentation/provider_labels.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One nearby provider: photo, name, badge, rating, jobs and distance (C10).
class ProviderCardView extends StatelessWidget {
  /// Creates the card.
  const ProviderCardView({required this.card, required this.onTap, super.key});

  /// The provider.
  final ProviderCard card;

  /// Opens the profile.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        onTap: onTap,
        child: Row(
          children: [
            PaoAvatar(name: card.name, image: photoOf(card.photoUrl), size: 56),
            const SizedBox(width: PaoSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PaoSpace.xs,
                children: [
                  Text(card.name, style: text.titleMedium),
                  PaoBadge(
                    label: badgeLabel(t, card.badge),
                    tone: badgeTone(card.badge),
                    icon: Icons.verified_outlined,
                  ),
                  _Facts(card: card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.card});

  final ProviderCard card;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rating = card.rating.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PaoRatingStars(
              rating: card.rating,
              size: 16,
              semanticLabel: context.common.ratingLabel(rating),
            ),
            const SizedBox(width: PaoSpace.xs),
            Text('$rating (${context.count(card.ratingCount)})'),
          ],
        ),
        Text(
          [
            t.provJobs(card.completedJobs, context.count(card.completedJobs)),
            distanceText(t, card.distanceM, context.lang),
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
