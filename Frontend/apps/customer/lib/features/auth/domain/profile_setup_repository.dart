import 'dart:typed_data';

/// Saves a new customer's basic profile (C-01: name, optional photo).
abstract interface class ProfileSetupRepository {
  /// Uploads [photo] if given, then saves [name] and [language].
  Future<void> save({
    required String name,
    required String language,
    Uint8List? photo,
  });
}

/// Whether [name] fits the profile's 2–80 characters once trimmed.
bool validName(String name) {
  final n = name.trim().runes.length;
  return n >= 2 && n <= 80;
}
