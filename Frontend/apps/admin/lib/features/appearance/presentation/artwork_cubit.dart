import 'package:pao_admin/features/appearance/domain/artwork_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The artwork slots; uploads and resets reload the list.
class ArtworkCubit extends LoadCubit<List<ArtworkSlot>> {
  /// Creates the cubit; call [load] to start.
  ArtworkCubit(this._repo) : super(_repo.slots);

  final ArtworkRepository _repo;

  /// Replaces slot [key]'s image; returns why not, or null.
  Future<AppFailure?> upload(String key, String type, List<int> file) =>
      _change(() => _repo.upload(key, type, file));

  /// Puts slot [key]'s original back; returns why not, or null.
  Future<AppFailure?> reset(String key) => _change(() => _repo.reset(key));

  Future<AppFailure?> _change(Future<void> Function() action) async {
    final failure = await attempt(action);
    if (failure == null) await refresh();
    return failure;
  }
}
