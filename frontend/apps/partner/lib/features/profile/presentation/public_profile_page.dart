import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/data/api_profile_repository.dart';
import 'package:pao_partner/features/profile/domain/profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/profile_labels.dart';
import 'package:pao_partner/features/profile/presentation/rating_summary.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The profile as customers see it (M29); never shows documents or phone.
class PublicProfilePage extends StatelessWidget {
  /// Creates the page.
  const PublicProfilePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        LoadCubit<ProfileOverview>(ApiProfileRepository(services.api).overview)
            .loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.profPublicTitle),
      body: BlocBuilder<LoadCubit<ProfileOverview>, ViewState<ProfileOverview>>(
        builder: (context, state) => ViewStateView<ProfileOverview>(
          state: state,
          onRetry: context.read<LoadCubit<ProfileOverview>>().load,
          builder: (_, overview) => _Preview(overview: overview),
        ),
      ),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.overview});

  final ProfileOverview overview;

  @override
  Widget build(BuildContext context) {
    final p = overview.profile;
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        Text(t.profPublicHint, style: text.bodySmall),
        const SizedBox(height: PaoSpace.lg),
        _Identity(profile: p),
        const SizedBox(height: PaoSpace.lg),
        if (p.bio?.isNotEmpty ?? false) Text(p.bio!),
        Text(
          t.profExperience(p.experienceYears, context.count(p.experienceYears)),
        ),
        const SizedBox(height: PaoSpace.md),
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
        const SizedBox(height: PaoSpace.xl),
        RatingSummary(rating: overview.rating),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final ProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.photoUrl;
    return Row(
      children: [
        PaoAvatar(name: profile.name, size: 64, image: photoOf(url)),
        const SizedBox(width: PaoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
              PaoBadge(
                label: badgeLabel(context.t, profile.badge),
                tone: badgeTone(profile.badge),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
