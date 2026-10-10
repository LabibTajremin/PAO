import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/step_titles.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Every step at a glance, then the submission for verification.
class ReviewStep extends StatelessWidget {
  /// Creates the review of [progress].
  const ReviewStep({required this.progress, super.key});

  /// Loaded progress.
  final EnrolProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cubit = context.read<EnrolmentCubit>();
    return StepBody(
      nextLabel: progress.submitted ? t.enrolGoVerification : t.enrolSubmit,
      onNext: switch (progress) {
        EnrolProgress(submitted: true) => () => context.go(Routes.verification),
        EnrolProgress(complete: true) => cubit.submit,
        _ => null,
      },
      children: [
        Text(progress.submitted ? t.enrolSubmittedBody : t.enrolReviewBody),
        const SizedBox(height: PaoSpace.md),
        for (final step in EnrolStep.values)
          PaoListRow(
            title: stepTitle(t, step),
            trailing: _badge(context, step),
            onTap: () => cubit.open(step),
          ),
      ],
    );
  }

  Widget _badge(BuildContext context, EnrolStep step) {
    final t = context.t;
    if (progress.isDone(step)) {
      return PaoBadge(label: t.enrolStepDone, tone: PaoTone.success);
    }
    final required = progress.steps.any((s) => s.step == step && s.required);
    return required
        ? PaoBadge(label: t.enrolStepTodo, tone: PaoTone.warning)
        : PaoBadge(label: t.enrolOptional);
  }
}
