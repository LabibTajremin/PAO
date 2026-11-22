import 'package:flutter/material.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/icon_picker.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Why the backend refused an icon, in words; other failures use the
/// common messages.
String? iconFailureText(BuildContext context, AppFailure? failure) {
  final t = context.t;
  final reason = failure is ApiFailure ? failure.details['reason'] : null;
  return switch (reason) {
    'icon_too_large' => t.iconErrorTooLarge,
    'icon_unreadable' => t.iconErrorUnreadable,
    'icon_not_square' => t.iconErrorNotSquare,
    'icon_too_small' => t.iconErrorTooSmall,
    'icon_opaque' => t.iconErrorOpaque,
    'icon_link_failed' => t.iconErrorLink,
    _ => context.failureText(failure),
  };
}

/// The content type of an icon file: its stated type when it is one the
/// backend takes (browsers often state none, or a generic one), else from the
/// name.
String? iconType(String? mimeType, String name) {
  const accepted = {'image/svg+xml', 'image/png', 'image/webp'};
  if (accepted.contains(mimeType)) return mimeType;
  final lower = name.toLowerCase();
  if (lower.endsWith('.svg')) return 'image/svg+xml';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}

/// Runs `store`, closes the picker with the stored icon's URL, or keeps it
/// open with the reason it failed.
mixin _Storing<T extends StatefulWidget> on State<T> {
  bool busy = false;
  AppFailure? failure;

  Future<void> run(Future<String> Function() store) async {
    setState(() => busy = true);
    try {
      final url = await store();
      if (mounted) Navigator.pop(context, (key: null, url: url));
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          failure = AppFailure.from(e);
        });
      }
    }
  }

  List<Widget> status(BuildContext context) => [
    if (busy) const LinearProgressIndicator(),
    if (iconFailureText(context, failure) case final text?)
      Text(text, style: TextStyle(color: context.pao.dangerInk)),
    Text(context.t.iconRules, style: Theme.of(context).textTheme.bodySmall),
  ];
}

/// Uploads an icon file the admin chooses.
class IconUploadTab extends StatefulWidget {
  /// Creates the tab.
  const IconUploadTab({
    required this.icons,
    required this.chooseFile,
    super.key,
  });

  /// Stores the upload.
  final CatalogRepository icons;

  /// Asks for the file.
  final IconFileChooser chooseFile;

  @override
  State<IconUploadTab> createState() => _IconUploadTabState();
}

class _IconUploadTabState extends State<IconUploadTab>
    with _Storing<IconUploadTab> {
  Future<void> _upload() async {
    final file = await widget.chooseFile();
    if (file == null) return;
    final type = iconType(file.mimeType, file.name);
    if (type == null) {
      return setState(
        () => failure = const ApiFailure(
          'VALIDATION_FAILED',
          status: 422,
          details: {'reason': 'icon_unreadable'},
        ),
      );
    }
    final bytes = await file.readAsBytes();
    await run(() => widget.icons.uploadIcon(type, bytes));
  }

  @override
  Widget build(BuildContext context) => _Pane(
    children: [
      PaoButton(
        label: context.t.iconUploadButton,
        icon: Icons.upload_file,
        onPressed: busy ? null : _upload,
      ),
      ...status(context),
    ],
  );
}

/// Adds an icon from an https link, downloaded once by the backend.
class IconLinkTab extends StatefulWidget {
  /// Creates the tab.
  const IconLinkTab({required this.icons, super.key});

  /// Fetches and stores the link.
  final CatalogRepository icons;

  @override
  State<IconLinkTab> createState() => _IconLinkTabState();
}

class _IconLinkTabState extends State<IconLinkTab> with _Storing<IconLinkTab> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Pane(
    children: [
      PaoTextField(
        label: context.t.iconLinkLabel,
        controller: _url,
        keyboardType: TextInputType.url,
      ),
      PaoButton(
        label: context.t.iconLinkAdd,
        onPressed: busy
            ? null
            : () => run(() => widget.icons.iconFromLink(_url.text.trim())),
      ),
      ...status(context),
    ],
  );
}

class _Pane extends StatelessWidget {
  const _Pane({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(PaoSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaoSpace.md,
      children: children,
    ),
  );
}
