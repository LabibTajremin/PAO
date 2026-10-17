import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Uploads through the provider upload endpoints (PRD §9.4).
MediaUploader providerUploader(Dio api, {Dio? storage}) {
  final client = ProviderApi(api);
  return MediaUploader(
    storage: storage,
    create: (file) async {
      final res = await client.createProviderUpload(
        uploadRequest: UploadRequest(
          purpose: UploadPurpose.values.firstWhere(
            (p) => p.value == file.purpose,
          ),
          contentType: UploadRequestContentTypeEnum.values.firstWhere(
            (c) => c.value == file.contentType,
          ),
          sizeBytes: file.bytes.length,
        ),
      );
      final t = res.data!;
      return SignedUpload(
        mediaId: t.mediaId,
        url: t.uploadUrl,
        headers: t.headers,
      );
    },
    confirm: (id) => client.confirmProviderUpload(mediaId: id),
  );
}
