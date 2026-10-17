import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/report/domain/report_repository.dart';
import 'package:pao_customer/features/report/presentation/report_cubit.dart';
import 'package:pao_customer/features/report/presentation/report_photos.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The words for each reason in [customerReasons].
Map<ComplaintReason, String> reasonLabels(CustomerL10n t) => {
  ComplaintReason.noShow: t.reportReasonNoShow,
  ComplaintReason.late_: t.reportReasonLate,
  ComplaintReason.poorQuality: t.reportReasonPoorQuality,
  ComplaintReason.overcharge: t.reportReasonOvercharge,
  ComplaintReason.damage: t.reportReasonDamage,
  ComplaintReason.behaviour: t.reportReasonBehaviour,
  ComplaintReason.safety: t.reportReasonSafety,
  ComplaintReason.payment: t.reportReasonPayment,
  ComplaintReason.other: t.reportReasonOther,
};

/// Reason, description and photos of a report (C20).
class ReportForm extends StatefulWidget {
  /// Creates the form; [photos] takes the pictures.
  const ReportForm({required this.photos, super.key});

  /// Camera and gallery.
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    final s = context.watch<ReportCubit>().state;
    final t = context.t;
    final labels = reasonLabels(t);
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        Text(t.reportIntro),
        const SizedBox(height: PaoSpace.xl),
        Text(t.reportReason, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: PaoSpace.sm),
        _Reasons(selected: s.reason, labels: labels, onTap: cubit.choose),
        // Error slots stay in the list even when empty: inserting rows would
        // rebuild the text field below and drop the keyboard.
        _Error(s.missingReason ? t.reportNeedReason : null),
        const SizedBox(height: PaoSpace.xl),
        PaoTextField(
          label: t.reportDescription,
          controller: _description,
          hint: t.reportDescriptionHint,
          maxLines: 5,
          error: s.badDescription ? t.reportDescriptionInvalid : null,
        ),
        const SizedBox(height: PaoSpace.xl),
        ReportPhotos(state: s, photos: widget.photos),
        _Error(context.failureText(s.failure)),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.reportSubmit,
          loading: s.sending,
          onPressed: () => cubit.submit(_description.text),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.message);

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return text == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: PaoSpace.sm),
            child: Text(text, style: const TextStyle(color: PaoColors.danger)),
          );
  }
}

class _Reasons extends StatelessWidget {
  const _Reasons({
    required this.selected,
    required this.labels,
    required this.onTap,
  });

  final ComplaintReason? selected;
  final Map<ComplaintReason, String> labels;
  final ValueChanged<ComplaintReason> onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PaoSpace.sm,
    runSpacing: PaoSpace.sm,
    children: [
      for (final reason in customerReasons)
        PaoChip(
          label: labels[reason]!,
          selected: selected == reason,
          onTap: () => onTap(reason),
        ),
    ],
  );
}
