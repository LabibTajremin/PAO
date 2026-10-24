import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/date_field.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/photo_slot.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M10: the police clearance certificate and its issue date.
class PoliceStep extends StatefulWidget {
  /// Creates the step; [today] bounds the issue date.
  const PoliceStep({required this.today, super.key});

  /// The current date.
  final DateTime today;

  @override
  State<PoliceStep> createState() => _PoliceStepState();
}

class _PoliceStepState extends State<PoliceStep> {
  DateTime? _issued;
  var _checked = false;

  Future<void> _save() async {
    setState(() => _checked = true);
    final id = context.read<UploadsCubit>().mediaId('police_clearance');
    final issued = _issued;
    if (id == null || issued == null) return;
    await context.read<EnrolmentCubit>().save(
      PoliceClearance(mediaId: id, issueDate: issued),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final id = context.watch<UploadsCubit>().mediaId('police_clearance');
    return StepBody(
      onNext: _save,
      children: [
        Text(t.enrolPoliceHint),
        const SizedBox(height: PaoSpace.lg),
        PhotoSlotView(
          slot: 'police_clearance',
          label: t.enrolStepPolice,
          modes: const [PhotoMode.camera, PhotoMode.gallery],
        ),
        if (_checked && id == null)
          Text(
            t.enrolPhotoError,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.lg),
        DateField(
          label: t.enrolIssueDate,
          value: _issued,
          first: DateTime(widget.today.year - 5),
          last: widget.today,
          onChanged: (d) => setState(() => _issued = d),
          error: _checked && _issued == null ? t.enrolIssueDateError : null,
        ),
      ],
    );
  }
}
