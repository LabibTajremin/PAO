import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The library icons, searchable, drawn in the accent colour as the apps do.
/// Tapping one picks its key.
class IconLibraryTab extends StatefulWidget {
  /// Creates the tab.
  const IconLibraryTab({required this.icons, super.key});

  /// Lists the library.
  final CatalogRepository icons;

  @override
  State<IconLibraryTab> createState() => _IconLibraryTabState();
}

class _IconLibraryTabState extends State<IconLibraryTab> {
  // The apps ship the same keys, so the picker still works if the list fails.
  late final Future<List<String>> _keys = widget.icons.iconLibrary().onError(
    (_, _) => paoIconKeys,
  );
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(PaoSpace.lg),
    child: Column(
      spacing: PaoSpace.md,
      children: [
        PaoTextField(label: context.t.iconSearch, controller: _search),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: _keys,
            builder: (context, snapshot) => ValueListenableBuilder(
              valueListenable: _search,
              builder: (context, query, _) => _grid(
                context,
                (snapshot.data ?? const <String>[])
                    .where((k) => k.contains(query.text.trim().toLowerCase()))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _grid(BuildContext context, List<String> keys) => GridView.extent(
    maxCrossAxisExtent: 104,
    mainAxisSpacing: PaoSpace.sm,
    crossAxisSpacing: PaoSpace.sm,
    children: [
      for (final key in keys)
        InkWell(
          borderRadius: PaoShape.leafSmall,
          onTap: () => Navigator.pop(context, (key: key, url: null)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: PaoSpace.xs,
            children: [
              PaoIconTile.service(iconKey: key),
              Text(
                key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
    ],
  );
}
