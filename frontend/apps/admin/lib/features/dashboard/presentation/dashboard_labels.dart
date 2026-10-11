import 'package:pao_admin/l10n/generated/admin_localizations.dart';

/// A provider account status from the dashboard breakdown; an unknown status
/// shows as sent so a new one on the server still reads.
String statusLabel(AdminL10n t, String status) => switch (status) {
  'pending' => t.dashStatusPending,
  'active' => t.dashStatusActive,
  'suspended' => t.dashStatusSuspended,
  'banned' => t.dashStatusBanned,
  _ => status,
};

/// A verification level key (`"0"`, `"1"`, `"2"`) from the breakdown.
String levelLabel(AdminL10n t, String level) => switch (level) {
  '0' => t.dashLevel0,
  '1' => t.dashLevel1,
  '2' => t.dashLevel2,
  _ => level,
};
