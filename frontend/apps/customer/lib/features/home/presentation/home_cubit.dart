import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/home/domain/home_repository.dart';

/// The home screen (C07): loads everything and switches the address.
class HomeCubit extends LoadCubit<HomeData> {
  /// Creates the cubit; call [load] to start.
  HomeCubit(this._repo) : super(_repo.load);

  final HomeRepository _repo;

  /// Makes [addressId] current and reloads; returns why it failed, if it did.
  Future<AppFailure?> switchTo(String addressId) async {
    final failure = await attempt(() => _repo.makeDefault(addressId));
    if (failure == null) await refresh();
    return failure;
  }
}
