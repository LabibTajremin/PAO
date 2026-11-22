import 'package:pao_api/pao_api.dart';

/// The app illustrations admins replace without a release (ADR-0040).
abstract interface class ArtworkRepository {
  /// Every slot with its size and current image.
  Future<List<ArtworkSlot>> slots();

  /// Replaces the image of slot [key] with [file] of [contentType].
  Future<ArtworkSlot> upload(String key, String contentType, List<int> file);

  /// Puts slot [key]'s original image back.
  Future<ArtworkSlot> reset(String key);
}
