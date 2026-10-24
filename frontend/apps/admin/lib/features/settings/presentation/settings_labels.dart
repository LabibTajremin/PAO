import 'package:pao_admin/features/settings/presentation/billing_settings.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';

/// A tab of the settings screen (A12) and the permission that shows it.
enum SettingsTab {
  /// Platform settings.
  settings('', 'settings:read'),

  /// Admin users.
  admins('admins', 'admin_user:manage'),

  /// Roles and their permissions.
  roles('roles', 'role:manage'),

  /// The audit log.
  audit('audit', 'audit:read');

  SettingsTab(this.path, this.permission);

  /// Path segment under `/settings`.
  final String path;

  /// Permission needed to see the tab.
  final String permission;

  /// Tab title.
  String label(AdminL10n t) => switch (this) {
    settings => t.settingsTabSettings,
    admins => t.settingsTabAdmins,
    roles => t.settingsTabRoles,
    audit => t.settingsTabAudit,
  };
}

/// An account role by its API name, as admins read it.
String roleLabel(AdminL10n t, String role) => switch (role) {
  'customer' => t.settingsRoleCustomer,
  'provider' => t.settingsRoleProvider,
  'verifier' => t.settingsRoleVerifier,
  'catalog_manager' => t.settingsRoleCatalogManager,
  'support_agent' => t.settingsRoleSupportAgent,
  'super_admin' => t.settingsRoleSuperAdmin,
  _ => role,
};

/// A setting's value as admins read it.
String settingValue(AdminL10n t, Setting s) => switch (s.type) {
  SettingTypeEnum.boolean => s.value == 'true' ? t.settingsOn : t.settingsOff,
  SettingTypeEnum.geojson => t.settingsShape,
  _ => billingSettingValue(t, s.key, s.value) ?? s.value,
};
