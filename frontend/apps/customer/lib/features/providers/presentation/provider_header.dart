import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/providers/presentation/provider_labels.dart';
import 'package:pao_customer/features/providers/presentation/review_widgets.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Photo, name, badge and track record of a provider (C11).
class ProviderHeader extends StatelessWidget {
  /// Creates the header.
  const ProviderHeader({required this.profile, super.key});

  /// The profile.
  final ProviderPublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PaoSpace.xs,
      children: [
        _Identity(profile: p),
        const SizedBox(height: PaoSpace.sm),
        Text(
          [
            t.provJobs(p.completedJobs, context.count(p.completedJobs)),
            t.provExperience(
              p.experienceYears,
              context.count(p.experienceYears),
            ),
          ].join(' · '),
        ),
        Text(
          t.provMemberSince(context.when(p.memberSince, 'MMM y')),
          style: text.bodySmall,
        ),
        TextButton.icon(
          icon: const Icon(Icons.info_outline),
          label: Text(t.provBadgeWhat),
          onPressed: () => showBadgeSheet(context),
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final ProviderPublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Row(
      children: [
        PaoAvatar(name: p.name, image: photoOf(p.photoUrl), size: 72),
        const SizedBox(width: PaoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PaoSpace.xs,
            children: [
              Text(p.name, style: Theme.of(context).textTheme.titleLarge),
              InkWell(
                onTap: () => showBadgeSheet(context),
                child: PaoBadge(
                  label: badgeLabel(context.t, p.badge),
                  tone: badgeTone(p.badge),
                  icon: Icons.verified_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
