import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/icon_library_tab.dart';
import 'package:pao_admin/features/catalog/presentation/icon_source_tabs.dart';
import 'package:pao_admin/shared/image_file.dart';
import 'package:pao_admin/shared/l10n.dart';

/// What the admin picked: a library key, or the URL of an icon they uploaded
/// or linked, which the backend has stored.
typedef IconPick = ({String? key, String? url});

/// Opens the icon picker; resolves with the pick, or null when dismissed.
Future<IconPick?> showIconPicker(
  BuildContext context, {
  required CatalogRepository icons,
  ImageFileChooser chooseFile = chooseImageFile,
}) => showDialog<IconPick>(
  context: context,
  builder: (_) => IconPickerDialog(icons: icons, chooseFile: chooseFile),
);

/// Library, upload and link tabs for choosing a category or service icon.
class IconPickerDialog extends StatelessWidget {
  /// Creates the dialog.
  const IconPickerDialog({
    required this.icons,
    required this.chooseFile,
    super.key,
  });

  /// Lists the library and stores uploads.
  final CatalogRepository icons;

  /// Asks for the file to upload.
  final ImageFileChooser chooseFile;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Dialog(
      child: SizedBox(
        width: 560,
        height: 520,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: t.iconTabLibrary),
                  Tab(text: t.iconTabUpload),
                  Tab(text: t.iconTabLink),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    IconLibraryTab(icons: icons),
                    IconUploadTab(icons: icons, chooseFile: chooseFile),
                    IconLinkTab(icons: icons),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
