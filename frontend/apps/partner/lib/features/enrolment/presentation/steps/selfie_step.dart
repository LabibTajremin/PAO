import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/photo_slot.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M09: a live selfie with the front camera; the gallery is not offered so
/// the photo is taken now (PRD §6.2 item 3).
class SelfieStep extends StatelessWidget {
  /// Creates the step.
  const SelfieStep({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final id = context.watch<UploadsCubit>().mediaId('selfie');
    return StepBody(
      onNext: id == null
          ? null
          : () => context.read<EnrolmentCubit>().save(SelfiePhoto(id)),
      children: [
        Text(t.enrolSelfieHint),
        const SizedBox(height: PaoSpace.lg),
        PhotoSlotView(
          slot: 'selfie',
          label: t.enrolStepSelfie,
          modes: const [PhotoMode.selfie],
        ),
      ],
    );
  }
}
