import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/account/domain/account_repository.dart';

/// Saved addresses (C24) with default and delete actions.
class AddressesCubit extends LoadCubit<List<Address>> {
  /// Creates the cubit; call [load] to start.
  AddressesCubit(AddressesRepository repo) : _repo = repo, super(repo.list);

  final AddressesRepository _repo;

  /// Makes [id] the default; returns why it failed, if it did.
  Future<AppFailure?> makeDefault(String id) =>
      _act(() => _repo.makeDefault(id));

  /// Deletes [id]; returns why it failed, if it did.
  Future<AppFailure?> delete(String id) => _act(() => _repo.delete(id));

  Future<AppFailure?> _act(Future<void> Function() action) async {
    final failure = await attempt(action);
    if (failure == null) await refresh();
    return failure;
  }
}
