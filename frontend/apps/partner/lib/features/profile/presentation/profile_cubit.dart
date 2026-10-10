import 'dart:typed_data';

import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/profile/domain/profile_repository.dart';

/// Loads the profile and rating, and saves bio and photo (M28).
class ProfileCubit extends LoadCubit<ProfileOverview> {
  /// Creates the cubit; call [load] to start.
  ProfileCubit(this._repo) : super(_repo.overview);

  final ProfileRepository _repo;

  /// Saves [bio]; returns why it failed, if it did.
  Future<AppFailure?> saveBio(String bio) => _save(bio: bio.trim());

  /// Uploads [photo] and makes it the profile photo; a cancelled capture
  /// passes null.
  Future<AppFailure?> changePhoto(Uint8List? photo) async {
    if (photo == null) return null;
    String? mediaId;
    final failure = await attempt(
      () async => mediaId = await _repo.uploadPhoto(photo),
    );
    return failure ?? await _save(photoMediaId: mediaId);
  }

  Future<AppFailure?> _save({String? bio, String? photoMediaId}) {
    final current = (state as ViewData<ProfileOverview>).data;
    return attempt(() async {
      final profile = await _repo.update(
        ProviderProfileUpdate(
          // The API requires the language on every update.
          language: current.profile.language,
          bio: bio,
          photoMediaId: photoMediaId,
        ),
      );
      emit(ViewData(ProfileOverview(profile, current.rating)));
    });
  }
}
