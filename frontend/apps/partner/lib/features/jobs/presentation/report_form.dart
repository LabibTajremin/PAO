import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/presentation/formats.dart';
import 'package:pao_partner/features/jobs/presentation/report_cubit.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Reasons a provider can report; the others in [ComplaintReason] are
/// customers' complaints about providers.
Map<ComplaintReason, String> providerReasons(PartnerL10n t) => {
  ComplaintReason.customerUnavailable: t.jobsReasonCustomerUnavailable,
  ComplaintReason.payment: t.jobsReasonPayment,
  ComplaintReason.behaviour: t.jobsReasonBehaviour,
  ComplaintReason.safety: t.jobsReasonSafety,
  ComplaintReason.damage: t.jobsReasonDamage,
  ComplaintReason.other: t.jobsReasonOther,
};

/// Reason, description and photos of a report (M25).
class ReportForm extends StatefulWidget {
  /// Creates the form; [photos] takes the pictures.
  const ReportForm({required this.photos, super.key});

  /// The camera.
  final PhotoSource photos;

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _capture(ReportCubit cubit) async =>
      cubit.addPhoto(await widget.photos.capture());

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    final s = context.watch<ReportCubit>().state;
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        Text(
          t.jobsReportReason,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PaoSpace.sm),
        _Reasons(selected: s.reason, onTap: cubit.choose),
        // Each slot stays in the list even when empty: inserting rows would
        // rebuild the text field below and drop the keyboard.
        _error(s.missingReason ? t.jobsReportNeedReason : null),
        const SizedBox(height: PaoSpace.xl),
        PaoTextField(
          label: t.jobsReportDescription,
          controller: _description,
          hint: t.jobsReportDescriptionHint,
          maxLines: 5,
          error: s.badDescription ? t.jobsReportDescriptionInvalid : null,
        ),
        const SizedBox(height: PaoSpace.xl),
        _Photos(state: s, onAdd: () => _capture(cubit)),
        _error(context.failureText(s.failure)),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.jobsReportSubmit,
          loading: s.sending,
          onPressed: () => cubit.submit(_description.text),
        ),
      ],
    );
  }

  Widget _error(String? message) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: PaoSpace.sm),
          child: Text(message, style: const TextStyle(color: PaoColors.danger)),
        );
}

class _Reasons extends StatelessWidget {
  const _Reasons({required this.selected, required this.onTap});

  final ComplaintReason? selected;
  final ValueChanged<ComplaintReason> onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.sm,
    runSpacing: PaoSpace.sm,
    children: [
      for (final MapEntry(key: reason, value: label) in providerReasons(
        context.t,
      ).entries)
        PaoChip(
          label: label,
          selected: selected == reason,
          onTap: () => onTap(reason),
        ),
    ],
  );
}

class _Photos extends StatelessWidget {
  const _Photos({required this.state, required this.onAdd});

  final ReportState state;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.jobsReportPhotos(
            context.count(state.photos.length),
            context.count(ReportCubit.maxPhotos),
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PaoSpace.sm),
        Wrap(
          spacing: PaoSpace.sm,
          runSpacing: PaoSpace.sm,
          children: [
            for (final (i, photo) in state.photos.indexed)
              Stack(
                children: [
                  Image.memory(photo, width: 72, height: 72, fit: BoxFit.cover),
                  IconButton(
                    tooltip: context.t.jobsReportRemovePhoto,
                    icon: const Icon(Icons.close, color: PaoColors.onPrimary),
                    onPressed: () => cubit.removePhoto(i),
                  ),
                ],
              ),
          ],
        ),
        PaoButton(
          label: context.t.jobsReportAddPhoto,
          icon: Icons.photo_camera_outlined,
          variant: PaoButtonVariant.outline,
          onPressed: state.canAddPhoto ? onAdd : null,
        ),
      ],
    );
  }
}
