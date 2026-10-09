import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Shrinks a photo before upload so it fits slow links and the size limits: the
/// longer side is at most [maxSide] pixels, re-encoded as JPEG at [quality].
/// Returns null when [bytes] is not an image.
Uint8List? compressPhoto(
  Uint8List bytes, {
  int maxSide = 1600,
  int quality = 80,
}) {
  final decoded = _decode(bytes);
  if (decoded == null) return null;
  final scale = maxSide / max(decoded.width, decoded.height);
  final resized = scale >= 1
      ? decoded
      : img.copyResize(
          decoded,
          width: (decoded.width * scale).round(),
          height: (decoded.height * scale).round(),
        );
  return img.encodeJpg(resized, quality: quality);
}

// Some decoders throw on truncated input instead of returning null.
img.Image? _decode(Uint8List bytes) {
  try {
    return img.decodeImage(bytes);
  } on Object {
    return null;
  }
}
