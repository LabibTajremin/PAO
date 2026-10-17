import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Runs [change] and reloads [cubit] when it worked; returns the failure.
Future<AppFailure?> _changeThenRefresh(
  LoadCubit<Object?> cubit,
  Future<void> Function() change,
) async {
  final failure = await attempt(change);
  if (failure == null) await cubit.refresh();
  return failure;
}

/// Platform settings (A-10).
class SettingsCubit extends LoadCubit<List<Setting>> {
  /// Creates the cubit; call [load] to start.
  SettingsCubit(this._repo) : super(_repo.settings);

  final SettingsRepository _repo;

  /// Changes setting [key] to [value].
  Future<AppFailure?> update(String key, String value) =>
      _changeThenRefresh(this, () => _repo.updateSetting(key, value));
}

/// Admin users (A-01): invite, change roles, deactivate.
class AdminUsersCubit extends LoadCubit<List<AdminUser>> {
  /// Creates the cubit; call [load] to start.
  AdminUsersCubit(this._repo) : super(_repo.adminUsers);

  final SettingsRepository _repo;

  /// Invites an admin; returns the one-time temporary password, or why not.
  Future<(String?, AppFailure?)> invite(AdminUserInvite invite) async {
    String? password;
    final failure = await _changeThenRefresh(
      this,
      () async => password = (await _repo.invite(invite)).temporaryPassword,
    );
    return (password, failure);
  }

  /// Changes roles or the active flag of admin [id].
  Future<AppFailure?> update(String id, AdminUserUpdate change) =>
      _changeThenRefresh(this, () => _repo.updateAdminUser(id, change));
}

/// Roles and their permissions and screens.
class RolesCubit extends LoadCubit<RoleList> {
  /// Creates the cubit; call [load] to start.
  RolesCubit(this._repo) : super(_repo.roles);

  final SettingsRepository _repo;

  /// Replaces what [role] may do and see; applies at once.
  Future<AppFailure?> save(Role role, RoleUpdate change) =>
      _changeThenRefresh(this, () => _repo.updateRole(role, change));
}
