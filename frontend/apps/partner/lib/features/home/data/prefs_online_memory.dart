import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/home/domain/online_memory.dart';

/// [OnlineMemory] in the device preferences.
class PrefsOnlineMemory implements OnlineMemory {
  /// Creates the memory over [_prefs].
  PrefsOnlineMemory(this._prefs);

  final Prefs _prefs;

  /// Preference key.
  static const key = 'pao.partner.online';

  @override
  bool get online => _prefs.flag(key);

  @override
  Future<void> remember({required bool online}) =>
      _prefs.setFlag(key, value: online);
}
