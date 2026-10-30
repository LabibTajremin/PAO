import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/features/verification/domain/verification.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Level 2 skill check: eligibility, the booked session or the cooling-off
/// period (PRD §6.3).
class SkillCheckCard extends StatelessWidget {
  /// Creates the card.
  const SkillCheckCard({required this.check, super.key});

  /// Level 2 info.
  final SkillCheck check;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final language = Localizations.localeOf(context).languageCode;
    String date(DateTime d) => formatDhaka(d, locale: language);
    final lines = [
      if (check.eligible) t.verifLevel2Eligible else t.verifLevel2NotEligible,
      if (check.sessionAt case final at?)
        t.verifLevel2Session(date(at), check.place ?? ''),
      if (check.retryAfter case final after?) t.verifLevel2Retry(date(after)),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: PaoSpace.xl),
      child: PaoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.verifLevel2Title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: PaoSpace.sm),
                child: Text(line),
              ),
          ],
        ),
      ),
    );
  }
}
