import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/profile/domain/profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/bio_sheet.dart';
import 'package:pao_partner/features/profile/presentation/profile_cubit.dart';
import 'package:pao_partner/features/profile/presentation/profile_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Photo, name, badge, level, rating and bio, with edit actions (M28).
class ProfileHeader extends StatelessWidget {
  /// Creates the header for [overview].
  const ProfileHeader({
    required this.overview,
    required this.photos,
    super.key,
  });

  /// Profile and rating.
  final ProfileOverview overview;

  /// The camera, for a new photo.
  final PhotoSource photos;

  Future<void> _changePhoto(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final photo = await photos.capture(selfie: true);
    final failure = await cubit.changePhoto(photo);
    if (context.mounted) _report(context, failure);
  }

  Future<void> _editBio(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final bio = await showBioSheet(context, overview.profile.bio ?? '');
    if (bio == null) return;
    final failure = await cubit.saveBio(bio);
    if (context.mounted) _report(context, failure);
  }

  void _report(BuildContext context, AppFailure? failure) {
    if (failure == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.failureText(failure)!)));
  }

  @override
  Widget build(BuildContext context) {
    final p = overview.profile;
    final url = p.photoUrl;
    final bio = p.bio ?? '';
    return PaoCard(
      child: Column(
        children: [
          PaoAvatar(name: p.name, size: 88, image: photoOf(url)),
          PaoButton(
            label: context.t.profChangePhoto,
            variant: PaoButtonVariant.ghost,
            expand: false,
            onPressed: () => _changePhoto(context),
          ),
          Text(p.name, style: Theme.of(context).textTheme.titleLarge),
          _Standing(overview: overview),
          Text(bio.isEmpty ? context.t.profNoBio : bio),
          PaoButton(
            label: context.t.profEditBio,
            variant: PaoButtonVariant.ghost,
            expand: false,
            onPressed: () => _editBio(context),
          ),
        ],
      ),
    );
  }
}

class _Standing extends StatelessWidget {
  const _Standing({required this.overview});

  final ProfileOverview overview;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = overview.profile;
    final rating = overview.rating;
    return Column(
      spacing: PaoSpace.sm,
      children: [
        Wrap(
          spacing: PaoSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PaoBadge(label: badgeLabel(t, p.badge), tone: badgeTone(p.badge)),
            Text(t.profLevelOf(context.count(p.level), levelName(t, p.level))),
          ],
        ),
        PaoRatingStars(
          rating: rating.average,
          semanticLabel: context.common.ratingLabel(
            rating.average.toStringAsFixed(1),
          ),
        ),
        Text(t.profRatingCount(rating.count, context.count(rating.count))),
      ],
    );
  }
}
