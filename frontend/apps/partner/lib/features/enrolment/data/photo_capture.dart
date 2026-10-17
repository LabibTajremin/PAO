import 'dart:typed_data';

import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';

/// Takes a photo with [photos] the way [mode] asks; null when cancelled.
Future<Uint8List?> capturePhoto(PhotoSource photos, PhotoMode mode) =>
    switch (mode) {
      PhotoMode.camera => photos.capture(),
      PhotoMode.selfie => photos.capture(selfie: true),
      PhotoMode.gallery => photos.pick(),
    };
