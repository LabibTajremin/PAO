/// Remembers the provider's online choice, so reopening the app or the home
/// screen resumes the heartbeat instead of silently dropping them offline.
abstract interface class OnlineMemory {
  /// Whether the provider was last online.
  bool get online;

  /// Stores the choice.
  Future<void> remember({required bool online});
}
