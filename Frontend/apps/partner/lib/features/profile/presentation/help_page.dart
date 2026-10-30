import 'package:flutter/material.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// PAO's partner support line, set per build with
/// `--dart-define=PAO_SUPPORT_PHONE=...`; the default is a placeholder until
/// operations publish the real number.
const supportPhone = String.fromEnvironment(
  'PAO_SUPPORT_PHONE',
  defaultValue: '09610000000',
);

/// Help topics and a call to support (M35). It works offline: nothing loads.
class HelpPage extends StatelessWidget {
  /// Creates the page.
  const HelpPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final topics = [
      (t.profHelpJobsQ, t.profHelpJobsA),
      (t.profHelpCodeQ, t.profHelpCodeA),
      (t.profHelpCashQ, t.profHelpCashA),
      (t.profHelpDocumentsQ, t.profHelpDocumentsA),
      (t.profHelpLevelQ, t.profHelpLevelA),
    ];
    return Scaffold(
      appBar: PaoAppBar(title: t.profHelpTitle),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.lg),
        children: [
          for (final (question, answer) in topics)
            ExpansionTile(
              title: Text(question),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.fromLTRB(
                PaoSpace.lg,
                0,
                PaoSpace.lg,
                PaoSpace.lg,
              ),
              children: [Text(answer)],
            ),
          const SizedBox(height: PaoSpace.xl),
          Text(t.profHelpStillStuck),
          const SizedBox(height: PaoSpace.md),
          PaoButton(
            label: t.profHelpCall,
            icon: Icons.call_outlined,
            onPressed: () => services.launcher.call(supportPhone),
          ),
        ],
      ),
    );
  }
}
