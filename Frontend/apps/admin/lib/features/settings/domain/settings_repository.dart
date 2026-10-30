import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Narrows the audit log; empty fields do not filter.
class AuditFilter {
  /// Creates the filter.
  const AuditFilter({
    this.actorId,
    this.action,
    this.subjectId,
    this.from,
    this.to,
  });

  /// Who acted.
  final String? actorId;

  /// Action name, e.g. `verification.item_approved`.
  final String? action;

  /// Subject ID.
  final String? subjectId;

  /// On or after.
  final DateTime? from;

  /// On or before.
  final DateTime? to;
}

/// Platform settings, admin users, roles and the audit log (A-08, A-10).
abstract interface class SettingsRepository {
  /// Every platform setting.
  Future<List<Setting>> settings();

  /// Changes setting [key] to [value], encoded as text.
  Future<Setting> updateSetting(String key, String value);

  /// Every admin user.
  Future<List<AdminUser>> adminUsers();

  /// Invites an admin; the reply holds the one-time temporary password.
  Future<AdminUserInvited> invite(AdminUserInvite invite);

  /// Changes an admin's roles or deactivates them.
  Future<AdminUser> updateAdminUser(String id, AdminUserUpdate change);

  /// Roles with their permissions and screens.
  Future<RoleList> roles();

  /// Replaces a role's permissions and screens.
  Future<RoleDefinition> updateRole(Role role, RoleUpdate change);

  /// One page of audit entries matching [filter], newest first.
  Future<Paged<AuditEntry>> audit(AuditFilter filter, {String? cursor});
}
