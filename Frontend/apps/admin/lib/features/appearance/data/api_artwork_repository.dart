import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pao_admin/features/appearance/domain/artwork_repository.dart';
import 'package:pao_api/pao_api.dart';

/// [ArtworkRepository] on the PAO API.
class ApiArtworkRepository implements ArtworkRepository {
  /// Creates the repository.
  ApiArtworkRepository(Dio api) : _api = AdminSettingsApi(api);

  final AdminSettingsApi _api;

  @override
  Future<List<ArtworkSlot>> slots() async =>
      (await _api.listArtwork()).data!.slots;

  @override
  Future<ArtworkSlot> upload(
    String key,
    String contentType,
    List<int> file,
  ) async => (await _api.uploadArtwork(
    slotKey: key,
    artworkUpload: ArtworkUpload(
      contentType: ArtworkUploadContentTypeEnum.values.firstWhere(
        (t) => t.value == contentType,
      ),
      data: base64Encode(file),
    ),
  )).data!;

  @override
  Future<ArtworkSlot> reset(String key) async =>
      (await _api.resetArtwork(slotKey: key)).data!;
}
