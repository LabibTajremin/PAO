import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/step_titles.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/area_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/conduct_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/contact_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/nid_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/personal_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/police_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/review_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/selfie_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/services_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/skill_step.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The wizard's frame: title, progress and the current step.
class EnrolmentView extends StatelessWidget {
  /// Creates the view; [requested] is the step the route asked for.
  const EnrolmentView({required this.requested, required this.now, super.key});

  /// Route step, reused when retrying the first load.
  final String requested;

  /// The current instant; the date pickers end on today in Dhaka.
  final DateTime now;

  Map<EnrolStep, Widget Function()> get _steps {
    final today = dhakaToday(now);
    return {
      EnrolStep.personal: () => PersonalStep(today: today),
      EnrolStep.services: ServicesStep.new,
      EnrolStep.area: AreaStep.new,
      EnrolStep.nid: NidStep.new,
      EnrolStep.selfie: SelfieStep.new,
      EnrolStep.policeClearance: () => PoliceStep(today: today),
      EnrolStep.skillProof: SkillStep.new,
      EnrolStep.emergencyContact: ContactStep.new,
      EnrolStep.codeOfConduct: ConductStep.new,
    };
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<EnrolmentCubit, EnrolState>(
        listenWhen: (before, now) => !before.finished && now.finished,
        listener: (context, _) => context.go(Routes.verification),
        builder: (context, s) => Scaffold(
          appBar: PaoAppBar(title: _title(context, s)),
          body: ViewStateView<EnrolProgress>(
            state: s.view,
            onRetry: () => context.read<EnrolmentCubit>().load(requested),
            builder: (_, progress) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepHeader(step: s.step),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(s.step),
                    child: s.step == null
                        ? ReviewStep(progress: progress)
                        : _steps[s.step]!(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _title(BuildContext context, EnrolState s) {
    if (s.progress == null) return context.t.enrolTitle;
    final step = s.step;
    return step == null
        ? context.t.enrolReviewTitle
        : stepTitle(context.t, step);
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final EnrolStep? step;

  @override
  Widget build(BuildContext context) {
    final total = EnrolStep.values.length;
    final number = (step?.index ?? total - 1) + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PaoSpace.xl,
        PaoSpace.md,
        PaoSpace.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: step == null ? 1 : number / total),
          const SizedBox(height: PaoSpace.xs),
          if (step != null)
            Text(
              context.t.enrolStepOf(number, total),
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }
}
