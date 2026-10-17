import 'dart:typed_data';

import 'package:pao_core/pao_core.dart';
import 'package:pao_e2e/src/jpeg.dart';

/// The device position, fixed in Banani where the e2e providers work.
class FixedLocation implements LocationService {
  /// Creates the service.
  const FixedLocation();

  @override
  Future<GeoPoint?> current() async => const GeoPoint(23.7937, 90.4066);
}

/// The camera and gallery, answering every request with [stubJpeg]: the
/// Linux runner has no camera, and the journey is about what happens next.
class StubPhotos extends PhotoSource {
  @override
  Future<Uint8List?> capture({bool selfie = false}) async => stubJpeg;

  @override
  Future<Uint8List?> pick() async => stubJpeg;
}
