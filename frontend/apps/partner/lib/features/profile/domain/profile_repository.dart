import 'dart:typed_data';

import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/jobs/domain/paged.dart';

/// The provider's profile and rating together (M28, M29).
class ProfileOverview {
  /// Creates the overview.
  const ProfileOverview(this.profile, this.rating);

  /// The own profile.
  final ProviderProfile profile;

  /// Rating received from customers.
  final RatingBreakdown rating;
}

/// The provider's profile, reviews and documents (P-10, P-11).
abstract interface class ProfileRepository {
  /// Loads the profile and rating.
  Future<ProfileOverview> overview();

  /// Saves bio, photo or language.
  Future<ProviderProfile> update(ProviderProfileUpdate change);

  /// Uploads a profile photo and returns its media ID.
  Future<String> uploadPhoto(Uint8List bytes);

  /// One page of reviews received, newest first.
  Future<Paged<Review>> reviews({String? cursor});

  /// Verification items with their status and expiry.
  Future<VerificationStatus> verification();
}
