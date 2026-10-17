import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_admin/features/settings/presentation/settings_cubits.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

import 'fixtures.dart';

class _Settings implements SettingsRepository {
  AppFailure? fail;
  int loads = 0;

  Future<T> _maybeFail<T>(T Function() value) async {
    if (fail != null) throw fail!;
    return value();
  }

  @override
  Future<List<Setting>> settings() async {
    loads++;
    return SettingList.fromJson(settingList()).items;
  }

  @override
  Future<Setting> updateSetting(String key, String value) =>
      _maybeFail(() => Setting.fromJson(setting(key, 'string', value)));

  @override
  Future<List<AdminUser>> adminUsers() async {
    loads++;
    return [AdminUser.fromJson(adminUser())];
  }

  @override
  Future<AdminUserInvited> invite(AdminUserInvite invite) => _maybeFail(
    () => AdminUserInvited.fromJson({
      'user': adminUser(),
      'temporaryPassword': 'secret-1',
    }),
  );

  @override
  Future<AdminUser> updateAdminUser(String id, AdminUserUpdate change) =>
      _maybeFail(() => AdminUser.fromJson(adminUser()));

  @override
  Future<RoleList> roles() async {
    loads++;
    return RoleList.fromJson(roleList());
  }

  @override
  Future<RoleDefinition> updateRole(Role role, RoleUpdate change) => _maybeFail(
    () => RoleDefinition.fromJson(
      (roleList()['items']! as List<Object?>).first! as Map<String, Object?>,
    ),
  );

  @override
  Future<Paged<AuditEntry>> audit(AuditFilter filter, {String? cursor}) async =>
      const Paged([]);
}

final _invite = AdminUserInvite(
  email: 'a@pao.bd',
  name: 'Ab',
  roles: [AdminRole.verifier],
);

void main() {
  test('settings reload after a change, not after a refusal', () async {
    final repo = _Settings();
    final cubit = SettingsCubit(repo);
    await cubit.load();
    expect(await cubit.update('k', 'v'), isNull);
    expect(repo.loads, 2);
    repo.fail = const NetworkFailure();
    expect((await cubit.update('k', 'v'))?.code, 'NETWORK');
    expect(repo.loads, 2);
  });

  test('an invite returns the password once, or the failure', () async {
    final repo = _Settings();
    final cubit = AdminUsersCubit(repo);
    expect(await cubit.invite(_invite), ('secret-1', null));
    expect(await cubit.update(rinaId, AdminUserUpdate(active: false)), isNull);
    repo.fail = const ApiFailure('CONFLICT', status: 409);
    final (password, failure) = await cubit.invite(_invite);
    expect((password, failure?.code), (null, 'CONFLICT'));
  });

  test('a role change is reported', () async {
    final repo = _Settings();
    final cubit = RolesCubit(repo);
    final change = RoleUpdate(permissions: [], screens: []);
    expect(await cubit.save(Role.verifier, change), isNull);
    repo.fail = const NetworkFailure();
    expect((await cubit.save(Role.verifier, change))?.code, 'NETWORK');
  });
}
