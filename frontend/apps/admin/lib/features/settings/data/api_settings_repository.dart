import 'package:dio/dio.dart';
import 'package:pao_admin/features/settings/domain/settings_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [SettingsRepository] on the PAO API.
class ApiSettingsRepository implements SettingsRepository {
  /// Creates the repository.
  ApiSettingsRepository(Dio api) : _api = AdminSettingsApi(api);

  final AdminSettingsApi _api;

  @override
  Future<List<Setting>> settings() async =>
      (await _api.listSettings()).data!.items;

  @override
  Future<Setting> updateSetting(String key, String value) async =>
      (await _api.updateSetting(
        key: key,
        settingUpdate: SettingUpdate(value: value),
      )).data!;

  @override
  Future<List<AdminUser>> adminUsers() async =>
      (await _api.listAdminUsers()).data!.items;

  @override
  Future<AdminUserInvited> invite(AdminUserInvite invite) async =>
      (await _api.inviteAdminUser(adminUserInvite: invite)).data!;

  @override
  Future<AdminUser> updateAdminUser(String id, AdminUserUpdate change) async =>
      (await _api.updateAdminUser(
        adminUserId: id,
        adminUserUpdate: change,
      )).data!;

  @override
  Future<RoleList> roles() async => (await _api.listRoles()).data!;

  @override
  Future<RoleDefinition> updateRole(Role role, RoleUpdate change) async =>
      (await _api.updateRole(role: role.value, roleUpdate: change)).data!;

  @override
  Future<Paged<AuditEntry>> audit(AuditFilter filter, {String? cursor}) async {
    final page = (await _api.listAuditEntries(
      actorId: filter.actorId,
      action: filter.action,
      subjectId: filter.subjectId,
      from: filter.from,
      to: filter.to,
      cursor: cursor,
    )).data!;
    return Paged(page.items, page.nextCursor);
  }
}
