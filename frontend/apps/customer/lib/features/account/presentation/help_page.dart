import 'package:flutter/material.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// PAO's customer support line, set per build with
/// `--dart-define=PAO_SUPPORT_PHONE=...`; the default is a placeholder until
/// operations publish the real number.
const supportPhone = String.fromEnvironment(
  'PAO_SUPPORT_PHONE',
  defaultValue: '09610000000',
);

/// PAO's support mailbox, set with `--dart-define=PAO_SUPPORT_EMAIL=...`.
const supportEmail = String.fromEnvironment(
  'PAO_SUPPORT_EMAIL',
  defaultValue: 'support@pao.com.bd',
);

/// Common questions and how to reach support (C27). It works offline:
/// nothing loads.
class HelpPage extends StatelessWidget {
  /// Creates the page.
  const HelpPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final topics = [
      (t.accountHelpBookQ, t.accountHelpBookA),
      (t.accountHelpPayQ, t.accountHelpPayA),
      (t.accountHelpCodeQ, t.accountHelpCodeA),
      (t.accountHelpCancelQ, t.accountHelpCancelA),
      (t.accountHelpProblemQ, t.accountHelpProblemA),
    ];
    return Scaffold(
      appBar: PaoAppBar(title: t.accountHelp),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.lg),
        children: [
          Text(
            t.accountHelpIntro,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
          _Contact(launcher: services.launcher),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.launcher});

  final Launcher launcher;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.accountHelpStillStuck),
        const SizedBox(height: PaoSpace.md),
        PaoButton(
          label: t.accountHelpCall,
          icon: Icons.call_outlined,
          onPressed: () => launcher.call(supportPhone),
        ),
        const SizedBox(height: PaoSpace.sm),
        PaoButton(
          label: t.accountHelpEmail,
          icon: Icons.mail_outline,
          variant: PaoButtonVariant.outline,
          onPressed: () =>
              launcher.email(supportEmail, subject: t.accountHelpEmailSubject),
        ),
      ],
    );
  }
}
