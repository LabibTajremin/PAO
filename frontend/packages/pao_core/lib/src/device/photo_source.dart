import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:pao_core/src/image_compress.dart';

/// Takes photos with the camera, compressed for upload.
class PhotoSource {
  /// Creates the source over [picker].
  PhotoSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Opens the camera ([selfie] uses the front one); null when cancelled.
  Future<Uint8List?> capture({bool selfie = false}) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
    );
    if (file == null) return null;
    return compressPhoto(await file.readAsBytes());
  }

  /// Picks a photo from the gallery, e.g. a scanned certificate.
  Future<Uint8List?> pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return compressPhoto(await file.readAsBytes());
  }
}
