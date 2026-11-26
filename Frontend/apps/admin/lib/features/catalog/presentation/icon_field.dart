import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/icon_picker.dart';
import 'package:pao_admin/shared/image_file.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The icon of a category or service: a library key and, optionally, an icon
/// the admin uploaded or linked. Shows it on a light and a dark tile as the
/// apps will, with the picker and the file rules.
class IconField extends StatelessWidget {
  /// Creates the field.
  const IconField({
    required this.keyController,
    required this.url,
    required this.icons,
    this.error,
    this.chooseFile = chooseImageFile,
    super.key,
  });

  /// The library key; also the fallback when the uploaded icon cannot load.
  final TextEditingController keyController;

  /// The uploaded icon's URL, null for the library icon.
  final ValueNotifier<String?> url;

  /// Lists the library and stores uploads.
  final CatalogRepository icons;

  /// Problem with the key.
  final String? error;

  /// Asks for a file to upload.
  final ImageFileChooser chooseFile;

  Future<void> _pick(BuildContext context) async {
    final pick = await showIconPicker(
      context,
      icons: icons,
      chooseFile: chooseFile,
    );
    if (pick == null) return;
    if (pick.key case final key?) keyController.text = key;
    url.value = pick.url;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([keyController, url]),
    builder: (context, _) {
      final t = context.t;
      final key = keyController.text.trim();
      Widget tile(ThemeData theme) => Theme(
        data: theme,
        child: Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(PaoSpace.xs),
            color: context.pao.card,
            child: PaoIconTile.service(iconKey: key, iconUrl: url.value),
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.sm,
        children: [
          Row(
            spacing: PaoSpace.md,
            children: [
              tile(PaoTheme.light()),
              tile(PaoTheme.dark()),
              Expanded(
                child: PaoTextField(
                  label: t.catalogIconKey,
                  controller: keyController,
                  error: error,
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _pick(context),
                child: Text(t.iconChoose),
              ),
            ],
          ),
          if (url.value != null) Text(t.iconUploaded),
          if (url.value != null)
            TextButton(
              onPressed: () => url.value = null,
              child: Text(t.iconUseLibrary),
            ),
          Text(t.iconRules, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    },
  );
}
