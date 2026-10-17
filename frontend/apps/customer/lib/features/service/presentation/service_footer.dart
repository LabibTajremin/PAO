import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/service/domain/selection.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The explanation of a [problem].
String problemText(CustomerL10n t, SelectionProblem problem) =>
    switch (problem) {
      SelectionProblem.empty => t.svcChooseHint,
      SelectionProblem.noStart => t.svcHireNeedStart,
      SelectionProblem.pastStart => t.svcHireStartPast,
    };

/// Total and "See providers" under a service (C09).
class ServiceFooter extends StatelessWidget {
  /// Creates the footer.
  const ServiceFooter({
    required this.service,
    required this.selection,
    required this.now,
    super.key,
  });

  /// The service.
  final Service service;

  /// The current selection.
  final Selection selection;

  /// The current time.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final problem = problemOf(service, selection, now);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PaoSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(context.t.svcTotal, style: text.titleMedium),
                ),
                PaoMoneyText(
                  totalOf(service, selection.items),
                  style: text.titleLarge,
                ),
              ],
            ),
            if (problem != null)
              Text(
                problemText(context.t, problem),
                style: const TextStyle(color: PaoColors.textSecondary),
              ),
            const SizedBox(height: PaoSpace.sm),
            PaoButton(
              label: context.t.svcSeeProviders,
              onPressed: problem != null
                  ? null
                  : () => context.push(
                      Uri(
                        path: Routes.providersOf(service.id),
                        queryParameters: draftOf(service, selection).toQuery(),
                      ).toString(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
