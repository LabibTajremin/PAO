import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/providers/data/api_providers_repository.dart';
import 'package:pao_customer/features/providers/domain/providers_repository.dart';
import 'package:pao_customer/features/providers/presentation/provider_header.dart';
import 'package:pao_customer/features/providers/presentation/review_widgets.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A provider's public profile (C11, C41) with the Book button.
class ProviderProfilePage extends StatelessWidget {
  /// Creates the page; [query] carries the booking draft, if any.
  const ProviderProfilePage({
    required this.services,
    required this.providerId,
    this.query = const {},
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The provider.
  final String providerId;

  /// The route's query parameters.
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<ProviderOverview>(
      () => ApiProvidersRepository(services.api).overview(providerId),
    ).loading(),
    child:
        BlocBuilder<LoadCubit<ProviderOverview>, ViewState<ProviderOverview>>(
          builder: (context, state) => Scaffold(
            appBar: const PaoAppBar(title: ''),
            body: ViewStateView<ProviderOverview>(
              state: state,
              onRetry: context.read<LoadCubit<ProviderOverview>>().load,
              builder: (_, overview) => _Profile(overview: overview),
            ),
            bottomNavigationBar: switch ((
              state,
              BookingDraft.fromQuery(query),
            )) {
              (ViewData(:final data), final draft?) => _BookBar(
                name: data.profile.name,
                onBook: () => context.push(
                  Uri(
                    path: Routes.book,
                    queryParameters: draft.withProvider(providerId).toQuery(),
                  ).toString(),
                ),
              ),
              _ => null,
            },
          ),
        ),
  );
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.name, required this.onBook});

  final String name;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(PaoSpace.lg),
      child: PaoButton(label: context.t.provBook(name), onPressed: onBook),
    ),
  );
}

class _Profile extends StatelessWidget {
  const _Profile({required this.overview});

  final ProviderOverview overview;

  @override
  Widget build(BuildContext context) {
    final p = overview.profile;
    final t = context.t;
    final heading = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        ProviderHeader(profile: p),
        if (p.bio.isNotEmpty) ...[
          Text(t.provAbout, style: heading),
          Text(p.bio),
          const SizedBox(height: PaoSpace.lg),
        ],
        Text(t.provServices, style: heading),
        const SizedBox(height: PaoSpace.sm),
        Wrap(
          spacing: PaoSpace.sm,
          runSpacing: PaoSpace.sm,
          children: [
            for (final s in p.services)
              PaoChip(
                label: context.local(s.name),
                selected: false,
                onTap: null,
              ),
          ],
        ),
        const SizedBox(height: PaoSpace.lg),
        Text(t.provRatings, style: heading),
        const SizedBox(height: PaoSpace.sm),
        RatingSummary(rating: p.rating),
        const SizedBox(height: PaoSpace.lg),
        _Reviews(overview: overview),
      ],
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.overview});

  final ProviderOverview overview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.t.provReviews,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: PaoSpace.sm),
      if (overview.reviews.isEmpty)
        Text(context.t.provNoReviews)
      else ...[
        for (final r in overview.reviews) ReviewCard(review: r),
        PaoButton(
          label: context.t.provAllReviews,
          variant: PaoButtonVariant.outline,
          onPressed: () =>
              context.push(Routes.providerReviewsOf(overview.profile.id)),
        ),
      ],
    ],
  );
}
