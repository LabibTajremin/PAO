import 'package:flutter/material.dart';
import 'package:pao_admin/features/providers/presentation/provider_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/ops/status_actions.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The reasons offered when suspending or banning a provider.
StatusPrompts providerPrompts(BuildContext context, String name) {
  final t = context.t;
  return StatusPrompts(
    name: name,
    banTitle: t.providersBanTitle(name),
    templates: [
      t.providersReasonNoShow,
      t.providersReasonComplaint,
      t.providersReasonRating,
      t.providersReasonFraud,
    ],
  );
}

/// Who the provider is, how they are doing, and the status actions when
/// [onChange] is set.
class ProviderProfileCard extends StatelessWidget {
  /// Creates the section.
  const ProviderProfileCard({
    required this.detail,
    required this.onChange,
    super.key,
  });

  /// The provider.
  final AdminProviderDetail detail;

  /// Changes the account status; null hides the actions.
  final Future<void> Function(AccountStatusChange change)? onChange;

  List<Widget> _facts(BuildContext context) {
    final t = context.t;
    final s = detail.summary;
    final services = [for (final r in s.services ?? <ServiceRef>[]) r.name];
    return [
      Fact(t.peopleRating, context.rating(s.rating)),
      Fact(t.providersJobs, context.count(s.completedJobs)),
      if (detail.complaints case final n?)
        Fact(t.providersComplaints, context.count(n)),
      if (detail.cancellations30d case final n?)
        Fact(t.providersCancellations, context.count(n)),
      if (detail.gender case final g?)
        Fact(t.providersGender, genderLabel(t, g)),
      if (detail.experienceYears case final y?)
        Fact(
          t.providersExperience,
          t.providersExperienceYears(context.count(y)),
        ),
      if (s.phone case final phone?) Fact(t.peoplePhone, phone),
      Fact(t.peopleJoined, context.when(s.createdAt, 'd MMM y')),
      if (services.isNotEmpty)
        Fact(t.providersServices, services.map(context.local).join(', ')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = detail.summary;
    return Section(
      title: context.t.providersProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.lg,
        children: [
          _Identity(summary: s),
          Wrap(
            spacing: PaoSpace.lg,
            runSpacing: PaoSpace.md,
            children: _facts(context),
          ),
          if (onChange case final change?)
            AccountStatusActions(
              status: s.status,
              prompts: providerPrompts(context, s.name),
              onChange: change,
            ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.summary});

  final AdminProviderSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = summary;
    return Row(
      spacing: PaoSpace.md,
      children: [
        PaoAvatar(name: s.name),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PaoSpace.xs,
            children: [
              Text(s.name, style: Theme.of(context).textTheme.titleLarge),
              Wrap(
                spacing: PaoSpace.sm,
                runSpacing: PaoSpace.xs,
                children: [
                  PaoBadge(
                    label: accountStatusLabel(t, s.status),
                    tone: accountStatusTone(s.status),
                  ),
                  PaoBadge(label: levelLabel(t, s.level), tone: PaoTone.accent),
                  if (s.flaggedForReview)
                    PaoBadge(label: t.providersFlagged, tone: PaoTone.danger),
                  if (s.online ?? false)
                    PaoBadge(label: t.providersOnline, tone: PaoTone.success),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Each verification item with its state (PRD §6).
class VerificationSummary extends StatelessWidget {
  /// Creates the section.
  const VerificationSummary({required this.items, super.key});

  /// The provider's verification items.
  final List<VerificationItem> items;

  String? _note(BuildContext context, VerificationItem item) {
    if (item.rejectionReason case final reason?) return reason;
    if (item.expiresAt case final at?) {
      return context.t.providersItemExpires(context.when(at, 'd MMM y'));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Section(
      title: t.providersVerification,
      child: items.isEmpty
          ? Text(t.providersNoItems)
          : Column(
              children: [
                for (final item in items)
                  PaoListRow(
                    title: item.required_
                        ? itemTypeLabel(t, item.type)
                        : '${itemTypeLabel(t, item.type)} · '
                              '${t.providersOptional}',
                    subtitle: _note(context, item),
                    trailing: PaoBadge(
                      label: itemStatusLabel(t, item.status),
                      tone: itemStatusTone(item.status),
                    ),
                  ),
              ],
            ),
    );
  }
}
