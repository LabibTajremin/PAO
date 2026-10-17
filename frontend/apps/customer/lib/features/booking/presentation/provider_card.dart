import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart' show Badge, BookingParty;
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The provider on booking screens: photo, name, badge, rating and, once the
/// booking is accepted, a call button (C12, C48, C49).
class PartyCard extends StatelessWidget {
  /// Creates the card.
  const PartyCard({
    required this.name,
    this.photoUrl,
    this.badge,
    this.rating,
    this.ratingCount,
    this.onCall,
    super.key,
  });

  /// The provider as shown on a booking.
  PartyCard.party(BookingParty party, {VoidCallback? onCall, Key? key})
    : this(
        name: party.name,
        photoUrl: party.photoUrl,
        badge: party.badge,
        rating: party.rating,
        ratingCount: party.ratingCount,
        onCall: onCall,
        key: key,
      );

  /// Full name.
  final String name;

  /// Profile photo.
  final String? photoUrl;

  /// Verification badge.
  final Badge? badge;

  /// Average stars.
  final double? rating;

  /// Number of reviews.
  final int? ratingCount;

  /// Opens the dialler; no button without it.
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return PaoCard(
      child: Row(
        children: [
          PaoAvatar(name: name, image: url == null ? null : NetworkImage(url)),
          const SizedBox(width: PaoSpace.md),
          Expanded(child: _Details(card: this)),
          if (onCall != null)
            IconButton.filledTonal(
              tooltip: context.t.liveCall,
              icon: const Icon(Icons.call_outlined),
              onPressed: onCall,
            ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.card});

  final PartyCard card;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rating = card.rating;
    final badge = switch (card.badge) {
      Badge.verified => t.bookingBadgeVerified,
      Badge.verifiedPro => t.bookingBadgePro,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: PaoSpace.xs),
        Wrap(
          spacing: PaoSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (badge != null)
              PaoBadge(
                label: badge,
                tone: PaoTone.success,
                icon: Icons.verified,
              ),
            if (rating != null)
              Text(
                t.bookingRating(
                  NumberFormat('0.0', context.lang).format(rating),
                  context.count(card.ratingCount ?? 0),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
