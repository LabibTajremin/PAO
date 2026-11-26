import 'package:file_selector/file_selector.dart';

/// Asks for one image file; tests pass their own.
typedef ImageFileChooser = Future<XFile?> Function();

/// Opens the browser's file chooser for SVG, PNG and WebP files.
Future<XFile?> chooseImageFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(
      label: 'SVG, PNG, WebP',
      extensions: ['svg', 'png', 'webp'],
      mimeTypes: ['image/svg+xml', 'image/png', 'image/webp'],
    ),
  ],
);

/// The content type of an image file: its stated type when it is one the
/// backend takes (browsers often state none, or a generic one), else from the
/// name.
String? imageType(String? mimeType, String name) {
  const accepted = {'image/svg+xml', 'image/png', 'image/webp'};
  if (accepted.contains(mimeType)) return mimeType;
  final lower = name.toLowerCase();
  if (lower.endsWith('.svg')) return 'image/svg+xml';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}
