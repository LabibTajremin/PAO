import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show ReviewTag;
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/rating/presentation/rating_cubit.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The provider being rated.
class RatingHeader extends StatelessWidget {
  /// Creates the header.
  const RatingHeader({required this.name, super.key});

  /// The provider's name.
  final String name;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PaoAvatar(name: name, size: 72),
      const SizedBox(height: PaoSpace.md),
      Text(
        context.t.ratingQuestion(name),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );
}

/// The tags a customer may pick, as chips.
class RatingTags extends StatelessWidget {
  /// Creates the chips.
  const RatingTags({required this.selected, required this.onToggle, super.key});

  /// Picked tags.
  final Set<ReviewTag> selected;

  /// Adds or removes a tag.
  final ValueChanged<ReviewTag> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.sm,
    runSpacing: PaoSpace.sm,
    children: [
      for (final tag in RatingCubit.tags)
        PaoChip(
          label: tagText(context.t, tag),
          selected: selected.contains(tag),
          onTap: () => onToggle(tag),
        ),
    ],
  );
}

/// The translated label of a provider [tag].
String tagText(CustomerL10n t, ReviewTag tag) => switch (tag) {
  ReviewTag.onTime => t.ratingTagOnTime,
  ReviewTag.professional => t.ratingTagProfessional,
  ReviewTag.qualityWork => t.ratingTagQuality,
  ReviewTag.clean => t.ratingTagClean,
  ReviewTag.friendly => t.ratingTagFriendly,
  ReviewTag.fairPrice => t.ratingTagFairPrice,
  ReviewTag.late_ => t.ratingTagLate,
  ReviewTag.rude => t.ratingTagRude,
  ReviewTag.poorQuality => t.ratingTagPoorQuality,
  _ => t.ratingTagMessy,
};

/// Thanks after rating (C55).
class ThanksView extends StatelessWidget {
  /// Creates the view.
  const ThanksView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PaoMessageState(
      icon: Icons.favorite_outline,
      title: t.ratingThanksTitle,
      message: t.ratingThanksBody,
      action: Column(
        children: [
          PaoButton(
            label: t.ratingMyBookings,
            onPressed: () => context.go(Routes.bookings),
          ),
          PaoButton(
            label: t.bookingBackHome,
            variant: PaoButtonVariant.ghost,
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
    );
  }
}
