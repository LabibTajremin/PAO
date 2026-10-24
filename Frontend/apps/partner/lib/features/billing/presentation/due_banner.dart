import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show DueSummary;
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/billing/domain/billing_repository.dart';
import 'package:pao_partner/features/billing/presentation/billing_labels.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Warns on the home screen when the due blocks accepting, or is close to it.
/// Shows nothing while loading or when the due cannot be read: the jobs below
/// matter more than the warning.
class DueBanner extends StatelessWidget {
  /// Creates the banner; it needs a `LoadCubit<DueSummary>` above it.
  const DueBanner({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LoadCubit<DueSummary>, ViewState<DueSummary>>(
        builder: (context, s) => switch (s) {
          ViewData(:final data) when dueNeedsAttention(data) => _banner(
            context,
            data,
          ),
          _ => const SizedBox.shrink(),
        },
      );

  Widget _banner(BuildContext context, DueSummary due) {
    final t = context.t;
    final amount = context.money(due.due);
    final limit = context.money(due.blockAmount);
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        highlighted: due.blocked,
        onTap: () => _open(context, Routes.billing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaoListRow(
              leading: Icon(
                due.blocked ? Icons.block_outlined : Icons.info_outline,
                color: due.blocked ? PaoColors.danger : null,
              ),
              title: due.blocked
                  ? t.billBannerBlocked(amount, limit)
                  : t.billBannerNear(amount, limit),
            ),
            PaoButton(
              label: t.billPayNow,
              variant: due.blocked
                  ? PaoButtonVariant.primary
                  : PaoButtonVariant.soft,
              onPressed: () => _open(context, Routes.pay),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<LoadCubit<DueSummary>>();
    await context.push(route);
    await cubit.refresh();
  }
}
