import 'package:pao_core/pao_core.dart';

/// Keeps each booking's start code on the device so it can be shown with no
/// network at the door (C36). The code is useless once the job has started,
/// so it is forgotten then.
class StartCodeCache {
  /// Creates the cache on [_prefs].
  const StartCodeCache(this._prefs);

  final Prefs _prefs;

  static String _key(String bookingId) => 'pao.startCode.$bookingId';

  /// The saved code, if any.
  String? read(String bookingId) {
    final code = _prefs.string(_key(bookingId));
    return code == null || code.isEmpty ? null : code;
  }

  /// Saves [code].
  Future<void> save(String bookingId, String code) =>
      _prefs.setString(_key(bookingId), code);

  /// Forgets the code; `Prefs` has no removal, so it is blanked.
  Future<void> forget(String bookingId) =>
      _prefs.setString(_key(bookingId), '');
}
