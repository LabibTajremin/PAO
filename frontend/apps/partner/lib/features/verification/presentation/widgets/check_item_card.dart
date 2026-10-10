import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/verification/domain/verification.dart';
import 'package:pao_partner/features/verification/presentation/verification_labels.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One checked item with its status, rejection reason, expiry and, when it
/// was refused or ran out, a way to upload it again.
class CheckItemCard extends StatelessWidget {
  /// Creates the card.
  const CheckItemCard({required this.item, super.key});

  /// The item.
  final CheckItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final secondary = Theme.of(context).textTheme.bodySmall!
        .copyWith(color: PaoColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(top: PaoSpace.md),
      child: PaoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(itemLabel(t, item.kind))),
                stateBadge(t, item.state),
              ],
            ),
            if (item.reason case final reason?)
              Text(t.verifReason(reason), style: secondary),
            if (item.expiresAt case final expires?)
              Text(_expiry(context, expires), style: secondary),
            if (item.needsUpload) ...[
              const SizedBox(height: PaoSpace.sm),
              PaoButton(
                label: t.verifReupload,
                icon: Icons.upload_outlined,
                variant: PaoButtonVariant.outline,
                onPressed: () =>
                    context.go(Routes.enrolStep(item.kind.step.key)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _expiry(BuildContext context, DateTime expires) {
    final date = formatDhaka(
      expires,
      pattern: 'd MMM y',
      locale: Localizations.localeOf(context).languageCode,
    );
    return item.state == ItemState.expired
        ? context.t.verifExpired(date)
        : context.t.verifExpires(date);
  }
}
