import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/photo_slot.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M08: NID number and both sides of the card, taken with the camera.
class NidStep extends StatefulWidget {
  /// Creates the step.
  const NidStep({super.key});

  @override
  State<NidStep> createState() => _NidStepState();
}

class _NidStepState extends State<NidStep> {
  final _number = TextEditingController();
  var _checked = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _checked = true);
    final uploads = context.read<UploadsCubit>();
    final front = uploads.mediaId('nid_front');
    final back = uploads.mediaId('nid_back');
    if (!validNid(_number.text) || front == null || back == null) return;
    await context.read<EnrolmentCubit>().save(
      NidDetails(number: _number.text, frontId: front, backId: back),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final uploads = context.watch<UploadsCubit>();
    final photosMissing =
        uploads.mediaId('nid_front') == null ||
        uploads.mediaId('nid_back') == null;
    return StepBody(
      onNext: _save,
      children: [
        PaoTextField(
          label: t.enrolNidNumber,
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          error: _checked && !validNid(_number.text) ? t.enrolNidError : null,
        ),
        const SizedBox(height: PaoSpace.lg),
        PhotoSlotView(slot: 'nid_front', label: t.enrolNidFront),
        const SizedBox(height: PaoSpace.md),
        PhotoSlotView(slot: 'nid_back', label: t.enrolNidBack),
        if (_checked && photosMissing)
          Text(
            t.enrolPhotoError,
            style: const TextStyle(color: PaoColors.danger),
          ),
      ],
    );
  }
}
