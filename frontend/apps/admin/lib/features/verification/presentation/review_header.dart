import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/features/verification/presentation/page_header.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The provider's name and level, the keyboard hint and "next provider".
class ReviewHeader extends StatelessWidget {
  /// Creates the header; [review] is null while it loads.
  const ReviewHeader({required this.review, required this.onNext, super.key});

  /// The loaded review.
  final VerificationReview? review;

  /// Opens the next provider; null disables it.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final r = review;
    return PageHeader(
      title: r?.profile.fullName ?? t.verifyReviewTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: t.verifyBackToQueue,
        onPressed: () => context.go(Routes.verification),
      ),
      subtitle: r == null
          ? null
          : PaoBadge(label: levelLabel(t, r.level), tone: PaoTone.accent),
      actions: [
        Text(
          t.verifyShortcuts,
          style: const TextStyle(color: PaoColors.textSecondary),
        ),
        PaoButton(
          label: t.verifyNext,
          icon: Icons.skip_next,
          variant: PaoButtonVariant.outline,
          expand: false,
          onPressed: onNext,
        ),
      ],
    );
  }
}
