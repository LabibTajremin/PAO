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

/// The API accepts up to ten skill photos.
const _maxPhotos = 10;

/// M11: optional certificates or work photos.
class SkillStep extends StatelessWidget {
  /// Creates the step.
  const SkillStep({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final uploads = context.watch<UploadsCubit>();
    final slots = uploads.slots('skill_proof');
    final ids = uploads.mediaIds('skill_proof');
    final next = 'skill_proof:${slots.length}';
    return StepBody(
      onNext: ids.isEmpty
          ? null
          : () => context.read<EnrolmentCubit>().save(SkillProof(ids)),
      extra: [
        PaoButton(
          label: t.enrolSkip,
          variant: PaoButtonVariant.ghost,
          onPressed: context.read<EnrolmentCubit>().skip,
        ),
      ],
      children: [
        Text(t.enrolSkillHint),
        for (final (i, slot) in slots.indexed) ...[
          const SizedBox(height: PaoSpace.md),
          PhotoSlotView(slot: slot, label: t.enrolSkillPhoto(i + 1)),
        ],
        if (slots.length < _maxPhotos) ...[
          const SizedBox(height: PaoSpace.lg),
          PaoButton(
            label: t.enrolTakePhoto,
            icon: Icons.photo_camera_outlined,
            variant: PaoButtonVariant.outline,
            onPressed: () => uploads.capture(next, PhotoMode.camera),
          ),
          const SizedBox(height: PaoSpace.sm),
          PaoButton(
            label: t.enrolChoosePhoto,
            icon: Icons.photo_library_outlined,
            variant: PaoButtonVariant.outline,
            onPressed: () => uploads.capture(next, PhotoMode.gallery),
          ),
        ],
      ],
    );
  }
}
