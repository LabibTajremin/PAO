import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/jobs/presentation/formats.dart';
import 'package:pao_partner/features/jobs/presentation/load_on_create.dart';
import 'package:pao_partner/features/jobs/presentation/paged_cubit.dart';
import 'package:pao_partner/features/jobs/presentation/paged_view.dart';
import 'package:pao_partner/features/profile/data/api_profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/profile_labels.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Reviews received from customers (M30).
class ReviewsPage extends StatelessWidget {
  /// Creates the page.
  const ReviewsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final repo = ApiProfileRepository(services.api);
    return BlocProvider(
      create: (_) =>
          PagedCubit<Review>((cursor) => repo.reviews(cursor: cursor))
              .loading(),
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.profReviewsTitle),
        body: PagedView<Review>(
          itemBuilder: (_, review) => ReviewCard(review: review),
          empty: PaoEmptyState(
            title: context.t.profReviewsEmpty,
            message: context.t.profReviewsEmptyBody,
            icon: Icons.star_outline,
          ),
        ),
      ),
    );
  }
}

/// One review: stars, author, service, comment and tags.
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
