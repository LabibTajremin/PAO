import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/appearance/data/api_artwork_repository.dart';
import 'package:pao_admin/features/appearance/presentation/artwork_card.dart';
import 'package:pao_admin/features/appearance/presentation/artwork_cubit.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/image_file.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Appearance › Illustrations: every artwork slot of the three apps, replaced
/// or reset without a release (ADR-0040).
class ArtworkPage extends StatelessWidget {
  /// Creates the page.
  const ArtworkPage({
    required this.services,
    this.chooseFile = chooseImageFile,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Asks for the file to upload.
  final ImageFileChooser chooseFile;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ArtworkCubit(ApiArtworkRepository(services.api)).loading(),
    child: BlocBuilder<ArtworkCubit, ViewState<List<ArtworkSlot>>>(
      builder: (context, state) => ConsolePage(
        title: context.t.appearanceTitle,
        child: ViewStateView<List<ArtworkSlot>>(
          state: state,
          onRetry: context.read<ArtworkCubit>().load,
          builder: (context, slots) => _Slots(
            slots: slots,
            canEdit: services.permissions.can('settings:manage'),
            chooseFile: chooseFile,
          ),
        ),
      ),
    ),
  );
}

class _Slots extends StatefulWidget {
  const _Slots({
    required this.slots,
    required this.canEdit,
    required this.chooseFile,
  });

  final List<ArtworkSlot> slots;
  final bool canEdit;
  final ImageFileChooser chooseFile;

  @override
  State<_Slots> createState() => _SlotsState();
}

class _SlotsState extends State<_Slots> {
  final _failures = <String, AppFailure?>{};

  Future<void> _upload(String key) async {
    final file = await widget.chooseFile();
    if (file == null || !mounted) return;
    final type = imageType(file.mimeType, file.name);
    final failure = type == null
        ? const ApiFailure(
            'VALIDATION_FAILED',
            status: 422,
            details: {'reason': 'artwork_unreadable'},
          )
        : await context.read<ArtworkCubit>().upload(
            key,
            type,
            await file.readAsBytes(),
          );
    _settle(key, failure);
  }

  Future<void> _reset(String key) async =>
      _settle(key, await context.read<ArtworkCubit>().reset(key));

  void _settle(String key, AppFailure? failure) {
    if (!mounted) return;
    setState(() => _failures[key] = failure);
    if (failure == null) showDone(context, context.t.formSaved);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(PaoSpace.xxl),
    children: [
      Text(context.t.appearanceRules),
      const SizedBox(height: PaoSpace.lg),
      Wrap(
        spacing: PaoSpace.lg,
        runSpacing: PaoSpace.lg,
        children: [
          for (final slot in widget.slots)
            ArtworkCard(
              slot: slot,
              failure: _failures[slot.key],
              onUpload: widget.canEdit ? () => _upload(slot.key) : null,
              onReset: widget.canEdit ? () => _reset(slot.key) : null,
            ),
        ],
      ),
    ],
  );
}
