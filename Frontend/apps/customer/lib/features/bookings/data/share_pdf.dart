import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares a PDF through the system share sheet (WhatsApp, email, files…).
Future<void> sharePdf(Uint8List bytes, String name) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
      fileNameOverrides: [name],
    ),
  );
}
