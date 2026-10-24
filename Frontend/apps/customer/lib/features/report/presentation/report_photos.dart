import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/report/presentation/report_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Up to five photos for a report, from the camera or the gallery.
class ReportPhotos extends StatelessWidget {
  /// Creates the section over [photos].
  const ReportPhotos({required this.state, required this.photos, super.key});

  /// The form state.
  final ReportState state;

  /// Camera and gallery.
  final PhotoSource photos;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    final canAdd = state.canAddPhoto && !state.sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.reportPhotos(
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
              _Thumb(photo: photo, onRemove: () => cubit.removePhoto(i)),
          ],
        ),
        const SizedBox(height: PaoSpace.sm),
        Row(
          children: [
            _AddButton(
              label: context.t.reportTakePhoto,
              icon: Icons.photo_camera_outlined,
              onAdd: canAdd ? photos.capture : null,
            ),
            const SizedBox(width: PaoSpace.sm),
            _AddButton(
              label: context.t.reportChoosePhoto,
              icon: Icons.photo_library_outlined,
              onAdd: canAdd ? photos.pick : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onRemove});

  final Uint8List photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(PaoRadius.sm),
        child: Image.memory(photo, width: 72, height: 72, fit: BoxFit.cover),
      ),
      IconButton(
        tooltip: context.t.reportRemovePhoto,
        icon: const Icon(Icons.close, color: PaoColors.onPrimary),
        onPressed: onRemove,
      ),
    ],
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.icon, this.onAdd});

  final String label;
  final IconData icon;
  final Future<Uint8List?> Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    final add = onAdd;
    final cubit = context.read<ReportCubit>();
    return Expanded(
      child: PaoButton(
        label: label,
        icon: icon,
        variant: PaoButtonVariant.outline,
        onPressed: add == null ? null : () async => cubit.addPhoto(await add()),
      ),
    );
  }
}
