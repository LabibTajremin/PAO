import 'package:flutter/material.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Terms and privacy (C28), readable before signing in.
class LegalPage extends StatelessWidget {
  /// Creates the page.
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = Theme.of(context).textTheme;
    final sections = [
      (t.accountLegalTermsHeading, t.accountLegalTermsBody),
      (t.accountLegalPrivacyHeading, t.accountLegalPrivacyBody),
      (t.accountLegalChoicesHeading, t.accountLegalChoicesBody),
    ];
    return Scaffold(
      appBar: PaoAppBar(title: t.accountLegal),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          for (final (heading, body) in sections) ...[
            Text(heading, style: text.titleMedium),
            const SizedBox(height: PaoSpace.sm),
            Text(body, style: text.bodyMedium),
            const SizedBox(height: PaoSpace.xl),
          ],
        ],
      ),
    );
  }
}
