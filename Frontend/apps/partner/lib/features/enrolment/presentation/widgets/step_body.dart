import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Layout shared by the wizard steps: the form, the last failure, the main
/// button and a way back.
class StepBody extends StatelessWidget {
  /// Creates the body; [onNext] null disables the main button and
  /// [showNext] false hides it, e.g. while a code is awaited.
  const StepBody({
    required this.children,
    required this.onNext,
    this.nextLabel,
    this.extra = const [],
    this.showNext = true,
    super.key,
  });

  /// The step's form.
  final List<Widget> children;

  /// Saves the step.
  final VoidCallback? onNext;

  /// Main button text; "Save and continue" when null.
  final String? nextLabel;

  /// Buttons under the main one, e.g. "Skip for now".
  final List<Widget> extra;

  /// Whether the main button is shown.
  final bool showNext;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EnrolmentCubit>();
    final s = cubit.state;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        ...children,
        if (s.failure != null) ...[
          const SizedBox(height: PaoSpace.md),
          Text(
            context.failureText(s.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        ],
        const SizedBox(height: PaoSpace.xxl),
        if (showNext)
          PaoButton(
            label: nextLabel ?? context.t.enrolSaveContinue,
            loading: s.saving,
            onPressed: onNext,
          ),
        ...extra,
        if (s.step != EnrolStep.personal)
          PaoButton(
            label: context.common.actionBack,
            variant: PaoButtonVariant.ghost,
            onPressed: cubit.back,
          ),
      ],
    );
  }
}
