import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/auth/domain/profile_setup_repository.dart';
import 'package:pao_customer/shared/uploads.dart';

/// [ProfileSetupRepository] on the PAO API.
class ApiProfileSetupRepository implements ProfileSetupRepository {
  /// Creates the repository; [onSaved] receives the stored profile.
  ApiProfileSetupRepository(
    Dio api, {
    required this.onSaved,
    MediaUploader? uploader,
  }) : _api = CustomerApi(api),
       _uploader = uploader ?? customerUploader(api);

  final CustomerApi _api;
  final MediaUploader _uploader;

  /// Called with the profile the API stored.
  final void Function(CustomerProfile profile) onSaved;

  @override
  Future<void> save({
    required String name,
    required String language,
    Uint8List? photo,
  }) async {
    final mediaId = photo == null
        ? null
        : await _uploader.upload(
            UploadFile(bytes: photo, purpose: UploadPurpose.avatar.value),
          );
    final res = await _api.updateCustomerProfile(
      customerProfileUpdate: CustomerProfileUpdate(
        name: name.trim(),
        language: Language.values.firstWhere((l) => l.value == language),
        photoMediaId: mediaId,
      ),
    );
    onSaved(res.data!);
  }
}
