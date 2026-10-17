import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_icons.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The icon key of a category or service with a preview of the icon the apps
/// draw for it and a menu of the keys they know.
class IconKeyField extends StatelessWidget {
  /// Creates the field.
  const IconKeyField({required this.controller, this.error, super.key});

  /// The key being edited.
  final TextEditingController controller;

  /// Problem with the key.
  final String? error;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: PaoSpace.md,
          children: [
            PaoIconTile(icon: catalogIcon(value.text.trim())),
            Expanded(
              child: PaoTextField(
                label: context.t.catalogIconKey,
                controller: controller,
                error: error,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: context.t.catalogPickIcon,
              icon: const Icon(Icons.apps),
              onSelected: (key) => controller.text = key,
              itemBuilder: (_) => [
                for (final key in knownIconKeys)
                  PopupMenuItem(
                    value: key,
                    child: ListTile(
                      leading: Icon(catalogIcon(key)),
                      title: Text(key),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}
