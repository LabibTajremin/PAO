import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// One photo to take and upload, with preview, progress and retry.
class PhotoSlotView extends StatelessWidget {
  /// Creates the slot view.
  const PhotoSlotView({
    required this.slot,
    required this.label,
    this.modes = const [PhotoMode.camera],
    super.key,
  });

  /// Slot key, e.g. `nid_front`.
  final String slot;

  /// What to photograph.
  final String label;

  /// Ways to add the photo.
  final List<PhotoMode> modes;

  @override
  Widget build(BuildContext context) {
    final uploads = context.watch<UploadsCubit>();
    final s = uploads.state[slot];
    final busy = s != null && s.uploading;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          if (s?.bytes != null) ...[
            const SizedBox(height: PaoSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(PaoRadius.md),
              child: Image.memory(s!.bytes!, height: 140, fit: BoxFit.cover),
            ),
          ],
          if (s != null) _SlotStatus(slot: slot, value: s),
          for (final mode in modes)
            Padding(
              padding: const EdgeInsets.only(top: PaoSpace.sm),
              child: PaoButton(
                label: _label(context, mode, retake: s?.bytes != null),
                icon: mode == PhotoMode.gallery
                    ? Icons.photo_library_outlined
                    : Icons.photo_camera_outlined,
                variant: PaoButtonVariant.outline,
                onPressed: busy ? null : () => uploads.capture(slot, mode),
              ),
            ),
        ],
      ),
    );
  }

  String _label(BuildContext context, PhotoMode mode, {required bool retake}) {
    if (mode == PhotoMode.gallery) return context.t.enrolChoosePhoto;
    return retake ? context.t.enrolRetake : context.t.enrolTakePhoto;
  }
}

class _SlotStatus extends StatelessWidget {
  const _SlotStatus({required this.slot, required this.value});

  final String slot;
  final UploadSlot value;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final child = switch (value) {
      UploadSlot(failure: final failure?) => Row(
        children: [
          Expanded(
            child: Text(
              '${t.enrolUploadFailed} ${context.failureText(failure)}',
              style: const TextStyle(color: PaoColors.danger),
            ),
          ),
          if (value.bytes != null)
            TextButton(
              onPressed: () => context.read<UploadsCubit>().retry(slot),
              child: Text(context.common.actionRetry),
            ),
        ],
      ),
      UploadSlot(mediaId: _?) => Align(
        alignment: Alignment.centerLeft,
        child: PaoBadge(
          label: t.enrolUploaded,
          tone: PaoTone.success,
          icon: Icons.check,
        ),
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: value.progress),
          Text(t.enrolUploading((value.progress * 100).round())),
        ],
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: PaoSpace.sm),
      child: child,
    );
  }
}
