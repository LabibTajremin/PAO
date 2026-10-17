import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/profile/domain/profile_repository.dart';
import 'package:pao_partner/shared/uploads.dart';

/// [ProfileRepository] on the PAO API.
class ApiProfileRepository implements ProfileRepository {
  /// Creates the repository.
  ApiProfileRepository(this._dio)
    : _api = ProviderApi(_dio),
      _enrolment = ProviderEnrolmentApi(_dio);

  final Dio _dio;
  final ProviderApi _api;
  final ProviderEnrolmentApi _enrolment;

  @override
  Future<ProfileOverview> overview() async {
    final profile = await _api.getProviderProfile();
    final rating = await _api.getMyRating();
    return ProfileOverview(profile.data!, rating.data!);
  }

  @override
  Future<ProviderProfile> update(ProviderProfileUpdate change) async =>
      (await _api.updateProviderProfile(providerProfileUpdate: change)).data!;

  @override
  Future<String> uploadPhoto(Uint8List bytes) => providerUploader(_dio)
      .upload(UploadFile(bytes: bytes, purpose: UploadPurpose.avatar.value));

  @override
  Future<Paged<Review>> reviews({String? cursor}) async {
    final res = await _api.listMyReviews(cursor: cursor);
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<VerificationStatus> verification() async =>
      (await _enrolment.getVerificationStatus()).data!;
}
