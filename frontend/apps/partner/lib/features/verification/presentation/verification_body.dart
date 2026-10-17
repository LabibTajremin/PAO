import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/gate.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/verification/domain/verification.dart';
import 'package:pao_partner/features/verification/presentation/verification_labels.dart';
import 'package:pao_partner/features/verification/presentation/widgets/check_item_card.dart';
import 'package:pao_partner/features/verification/presentation/widgets/skill_check_card.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The loaded M14 content.
class VerificationBody extends StatelessWidget {
  /// Creates the body.
  const VerificationBody({
    required this.summary,
    required this.gate,
    super.key,
  });

  /// What to show.
  final VerificationSummary summary;

  /// The app's gate; once cleared the provider may go home.
  final ProviderGate gate;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        _LevelCard(summary: summary),
        ListenableBuilder(
          listenable: gate,
          builder: (context, _) => gate.cleared
              ? _action(t.verifGoHome, () => context.go(Routes.home))
              : const SizedBox.shrink(),
        ),
        ?_resume(context),
        const SizedBox(height: PaoSpace.xl),
        Text(t.verifItemsTitle, style: Theme.of(context).textTheme.titleMedium),
        if (summary.items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: PaoSpace.md),
            child: Text(t.verifNoItems),
          ),
        for (final item in summary.items) CheckItemCard(item: item),
        if (summary.skillCheck case final check?) SkillCheckCard(check: check),
      ],
    );
  }

  Widget? _resume(BuildContext context) {
    final t = context.t;
    if (summary.nextStep case final step?) {
      return _action(
        t.verifContinue,
        () => context.go(Routes.enrolStep(step.key)),
      );
    }
    if (summary.submitted) return null;
    return _action(t.verifSubmit, () => context.go(Routes.enrolStep('review')));
  }

  Widget _action(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(top: PaoSpace.lg),
    child: PaoButton(label: label, onPressed: onPressed),
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.summary});

  final VerificationSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    return PaoCard(
      highlighted: summary.cleared,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.verifLevel(summary.level),
                  style: text.titleLarge,
                ),
              ),
              PaoBadge(
                label: badgeLabel(t, summary.badge),
                tone: summary.badge == TrustBadge.none
                    ? PaoTone.neutral
                    : PaoTone.success,
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: PaoSpace.sm),
          Text(statusMessage(t, summary)),
        ],
      ),
    );
  }
}
