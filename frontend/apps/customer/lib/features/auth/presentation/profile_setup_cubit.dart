import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/auth/domain/profile_setup_repository.dart';

/// Profile set-up (C05).
class ProfileSetupState {
  /// Creates the state.
  const ProfileSetupState({
    this.photo,
    this.saving = false,
    this.invalidName = false,
    this.failure,
    this.done = false,
  });

  /// The chosen photo, if any.
  final Uint8List? photo;

  /// The profile is being saved.
  final bool saving;

  /// The name is too short or too long.
  final bool invalidName;

  /// Why saving failed.
  final AppFailure? failure;

  /// Saved; the page moves on to the location step.
  final bool done;
}

/// Holds the chosen photo and saves the profile.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  /// Creates the cubit.
  ProfileSetupCubit(this._repo) : super(const ProfileSetupState());

  final ProfileSetupRepository _repo;

  /// Uses [bytes] as the profile photo; null keeps the current one.
  void photo(Uint8List? bytes) {
    if (bytes != null) emit(ProfileSetupState(photo: bytes));
  }

  /// Saves [name] in [language] with the chosen photo.
  Future<void> save(String name, String language) async {
    final photo = state.photo;
    if (!validName(name)) {
      return emit(ProfileSetupState(photo: photo, invalidName: true));
    }
    emit(ProfileSetupState(photo: photo, saving: true));
    final failure = await attempt(
      () => _repo.save(name: name, language: language, photo: photo),
    );
    emit(
      ProfileSetupState(photo: photo, failure: failure, done: failure == null),
    );
  }
}
