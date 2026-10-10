import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/providers/data/api_providers_repository.dart';
import 'package:pao_customer/features/providers/presentation/review_widgets.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// All reviews of a provider (C42).
class ReviewsPage extends StatelessWidget {
  /// Creates the page.
  const ReviewsPage({
    required this.services,
    required this.providerId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The provider.
  final String providerId;

  @override
  Widget build(BuildContext context) {
    final repo = ApiProvidersRepository(services.api);
    return BlocProvider(
      create: (_) => PagedCubit<Review>(
        (cursor) => repo.reviews(providerId, cursor: cursor),
      ).loading(),
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.provAllReviews),
        body: PagedView<Review>(
          itemBuilder: (_, review) => ReviewCard(review: review),
          empty: PaoEmptyState(
            icon: Icons.star_outline,
            title: context.t.provNoReviews,
            message: context.t.provNoReviewsBody,
          ),
        ),
      ),
    );
  }
}
