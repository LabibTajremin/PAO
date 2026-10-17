import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M13: the code of conduct, accepted with a checkbox.
class ConductStep extends StatefulWidget {
  /// Creates the step.
  const ConductStep({super.key});

  @override
  State<ConductStep> createState() => _ConductStepState();
}

class _ConductStepState extends State<ConductStep> {
  var _accepted = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rules = [
      t.enrolConductRule1,
      t.enrolConductRule2,
      t.enrolConductRule3,
      t.enrolConductRule4,
      t.enrolConductRule5,
    ];
    return StepBody(
      onNext: _accepted
          ? () => context.read<EnrolmentCubit>().save(const ConductAcceptance())
          : null,
      children: [
        Text(
          t.enrolConductIntro,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final rule in rules)
          Padding(
            padding: const EdgeInsets.only(top: PaoSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: PaoSpace.sm),
                Expanded(child: Text(rule)),
              ],
            ),
          ),
        const SizedBox(height: PaoSpace.lg),
        CheckboxListTile(
          value: _accepted,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(t.enrolConductAccept),
          onChanged: (v) => setState(() => _accepted = v!),
        ),
      ],
    );
  }
}
